import fs from "fs";
import path from "path";

const speakerOrder = ["I", "E", "O", "V", "untagged"];
const speakerLabel = {
  I: "I informant",
  E: "E interviewer",
  O: "O",
  V: "V",
  untagged: "untagged",
};

const fold = (value) =>
  value.normalize("NFD").replace(/\p{M}/gu, "").toLowerCase();

const countBy = (items, keyOf) => {
  const counts = new Map();
  for (const item of items) {
    const key = keyOf(item);
    counts.set(key, (counts.get(key) ?? 0) + 1);
  }
  return counts;
};

const byCount = (counts) =>
  [...counts.entries()].sort(
    (left, right) => right[1] - left[1] || String(left[0]).localeCompare(String(right[0]), "es")
  );

const interviewCode = /^[A-Za-z]+_([HM])([0-9][0-9A-Za-z])_/i;

const linesOf = (entries, total, labelOf = (key) => key) =>
  entries
    .map(([key, count]) => {
      const raw = total > 0 ? (count / total) * 100 : 0;
      const share = raw > 0 && raw < 0.1 ? "<0.1" : raw.toFixed(1);
      return `${String(count).padStart(6)}  ${share.padStart(5)}%  ${labelOf(key)}`;
    })
    .join("\n");

export const writeStats = (results, outputDirectory, meta = {}) => {
  const highlighted = [];
  const excludedWords = [];
  const fileRows = [];

  for (const result of results) {
    const kept = [];
    for (const gerund of result.gerunds ?? []) {
      if (gerund.excluded) excludedWords.push(gerund);
      else {
        highlighted.push({ ...gerund, code: result.code });
        kept.push(gerund);
      }
    }

    const speakers = countBy(kept, (gerund) => gerund.speaker);
    fileRows.push({
      file: result.file,
      code: result.code,
      failed: result.failed,
      highlighted: result.highlighted,
      excluded: result.excluded,
      informant: speakers.get("I") ?? 0,
      interviewer: speakers.get("E") ?? 0,
      other:
        kept.length - (speakers.get("I") ?? 0) - (speakers.get("E") ?? 0),
    });
  }

  const successful = fileRows.filter((row) => !row.failed);
  const typeCounts = countBy(highlighted, (gerund) => gerund.word);
  const excludedCounts = countBy(excludedWords, (gerund) => gerund.word);
  const endingCounts = countBy(
    highlighted.filter((gerund) => gerund.ending),
    (gerund) => fold(gerund.ending)
  );
  const speakerCounts = countBy(highlighted, (gerund) => gerund.speaker);
  const cliticCounts = countBy(
    highlighted.filter((gerund) => gerund.clitic !== ""),
    (gerund) => gerund.clitic
  );
  const sexCounts = new Map();
  const groupCounts = new Map();

  for (const gerund of highlighted) {
    const match = gerund.code.match(interviewCode);
    if (!match) continue;
    const sex = match[1].toUpperCase();
    const group = `${sex}${match[2].toUpperCase()}`;
    sexCounts.set(sex, (sexCounts.get(sex) ?? 0) + 1);
    groupCounts.set(group, (groupCounts.get(group) ?? 0) + 1);
  }

  const counts = successful.map((row) => row.highlighted);
  const min = successful.reduce(
    (best, row) => (row.highlighted < best.highlighted ? row : best),
    successful[0]
  );
  const max = successful.reduce(
    (best, row) => (row.highlighted > best.highlighted ? row : best),
    successful[0]
  );
  const mean =
    counts.length === 0
      ? 0
      : counts.reduce((sum, count) => sum + count, 0) / counts.length;
  const withPronoun = highlighted.filter((gerund) => gerund.clitic !== "").length;
  const acrossTag = highlighted.filter((gerund) => gerund.crossesTag).length;
  const hapax = [...typeCounts.values()].filter((count) => count === 1).length;

  const kind = meta.kind ?? "gerundios";
  const gerundQuery = kind === "gerundios";
  const shareOfHighlighted = (count) =>
    highlighted.length === 0 ? "0.0" : ((count / highlighted.length) * 100).toFixed(1);

  const sections = [];
  if (meta.request || meta.reading) {
    sections.push(
      `Consulta: ${meta.request ?? ""}`,
      meta.reading ?? "",
      ""
    );
  }
  sections.push(
    `Files: ${successful.length} processed, ${fileRows.length - successful.length} failed`,
    `Highlighted: ${highlighted.length} (${typeCounts.size} types, ${hapax} once)`,
    `Excluded: ${excludedWords.length} (${excludedCounts.size} types)`,
    `Mean per file: ${counts.length === 0 ? "0" : mean.toFixed(1)}${min ? ` (min ${min.highlighted} ${min.code}, max ${max.highlighted} ${max.code})` : ""}`
  );
  if (gerundQuery) {
    sections.push(
      `With a pronoun: ${withPronoun} (${shareOfHighlighted(withPronoun)}%)`,
      `Joined across a transcription tag: ${acrossTag} (${shareOfHighlighted(acrossTag)}%)`
    );
  }
  sections.push(
    "",
    "By speaker",
    linesOf(
      speakerOrder
        .filter((speaker) => speakerCounts.has(speaker))
        .map((speaker) => [speaker, speakerCounts.get(speaker)]),
      highlighted.length,
      (speaker) => speakerLabel[speaker] ?? speaker
    ),
    "",
    "By sex in the interview code",
    linesOf(byCount(sexCounts), highlighted.length, (sex) => (sex === "H" ? "H men" : "M women")),
    "",
    "By interview group",
    linesOf(byCount(groupCounts), highlighted.length)
  );
  if (gerundQuery || endingCounts.size > 0) {
    sections.push("", "By ending", linesOf(byCount(endingCounts), highlighted.length));
  }
  if (gerundQuery || cliticCounts.size > 0) {
    sections.push("", "Pronouns", linesOf(byCount(cliticCounts), highlighted.length));
  }
  sections.push(
    "",
    "Top types",
    linesOf(byCount(typeCounts).slice(0, 30), highlighted.length),
    "",
    "Top excluded",
    linesOf(byCount(excludedCounts).slice(0, 20), excludedWords.length)
  );
  const summary = sections.join("\n");

  fs.mkdirSync(outputDirectory, { recursive: true });
  const statsPath = path.join(outputDirectory, "stats.txt");
  fs.writeFileSync(statsPath, `${summary}\n`);

  const typePath = path.join(outputDirectory, "gerunds-by-type.tsv");
  const formHeader = gerundQuery ? "gerund" : "form";
  const typeRows = byCount(typeCounts).map(([word, count]) => {
    const sample = highlighted.find((gerund) => gerund.word === word);
    return `${count}\t${word}\t${fold(sample.ending)}\t${sample.clitic}`;
  });
  fs.writeFileSync(
    typePath,
    `count\t${formHeader}\tending\tclitic\n${typeRows.join("\n")}\n`
  );

  const filePath = path.join(outputDirectory, "gerunds-by-file.tsv");
  const fileLines = successful
    .slice()
    .sort((left, right) => left.code.localeCompare(right.code, "es"))
    .map(
      (row) =>
        `${row.highlighted}\t${row.excluded}\t${row.informant}\t${row.interviewer}\t${row.other}\t${row.code}\t${row.file}`
    );
  fs.writeFileSync(
    filePath,
    `highlighted\texcluded\tinformant\tinterviewer\tother\tcode\tfile\n${fileLines.join("\n")}\n`
  );

  return { summary, statsPath, typePath, filePath };
};
