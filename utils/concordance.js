import fs from "fs";
import path from "path";

const fold = (value) =>
  value.normalize("NFD").replace(/\p{M}/gu, "").toLowerCase();

const interviewCode = /^[A-Za-z]+_([HM])([0-9][0-9A-Za-z])_/i;

const bump = (map, key) => {
  if (!key) return;
  map.set(key, (map.get(key) ?? 0) + 1);
};

const objectFrom = (map) => Object.fromEntries(map);

export const hitsFile = (outputDirectory) =>
  path.join(outputDirectory, "concordance-hits.json");

export const writeConcordance = (results, outputDirectory, meta = {}) => {
  const hits = [];

  for (const result of results) {
    if (result.failed) continue;
    const parsed = result.code.match(interviewCode);
    const sex = parsed ? parsed[1].toUpperCase() : "";
    const group = parsed ? `${sex}${parsed[2].toUpperCase()}` : "";

    for (const gerund of result.gerunds ?? []) {
      if (gerund.excluded) continue;
      hits.push({
        id: `${result.code}-${hits.length}`,
        code: result.code,
        sex,
        group,
        speaker: gerund.speaker,
        word: gerund.word,
        ending: fold(gerund.ending ?? ""),
        clitic: gerund.clitic ?? "",
        crossesTag: Boolean(gerund.crossesTag),
        before: gerund.before ?? "",
        match: gerund.match ?? gerund.word,
        after: gerund.after ?? "",
        paragraph: Number.isInteger(gerund.paragraph) ? gerund.paragraph : null,
      });
    }
  }

  return publishConcordance(hits, outputDirectory, meta);
};

export const publishConcordance = (hits, outputDirectory, meta = {}) => {
  const speakers = new Map();
  const sexes = new Map();
  const groups = new Map();
  const endings = new Map();
  const types = new Map();
  let withPronoun = 0;

  for (const hit of hits) {
    bump(speakers, hit.speaker);
    bump(sexes, hit.sex);
    bump(groups, hit.group);
    if (hit.ending) bump(endings, hit.ending);
    if (hit.clitic) withPronoun += 1;
    const type = types.get(hit.word);
    if (type) type.count += 1;
    else types.set(hit.word, { count: 1, ending: hit.ending ?? "" });
  }

  const typeList = [...types.entries()]
    .map(([word, value]) => ({ word, count: value.count, ending: value.ending }))
    .sort((left, right) => right.count - left.count || left.word.localeCompare(right.word, "es"));

  fs.mkdirSync(outputDirectory, { recursive: true });
  const outputPath = path.join(outputDirectory, "concordance.json");
  fs.writeFileSync(
    outputPath,
    JSON.stringify({
      count: hits.length,
      request: meta.request ?? "gerundios",
      reading:
        meta.reading ??
        "Gerundios en -ando, -iendo o -yendo, con o sin pronombre.",
      kind: meta.kind ?? "gerundios",
      speakers: objectFrom(speakers),
      sexes: objectFrom(sexes),
      groups: objectFrom(groups),
      endings: objectFrom(endings),
      withPronoun,
      types: typeList,
    })
  );

  const hitsPath = hitsFile(outputDirectory);
  const handle = fs.openSync(hitsPath, "w");
  fs.writeSync(handle, "[");
  for (let index = 0; index < hits.length; index += 1) {
    if (index > 0) fs.writeSync(handle, ",");
    fs.writeSync(handle, JSON.stringify(hits[index]));
  }
  fs.writeSync(handle, "]");
  fs.closeSync(handle);

  return outputPath;
};
