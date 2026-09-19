import fs from "fs";
import path from "path";
import mammoth from "mammoth";
import { loadExclusionList } from "./exclusion-list.js";
import { interpret } from "./interpret.js";
import { searchParagraph } from "./search.js";
import { paragraphsFromText } from "./paragraphs.js";
import { readCache, writeCache } from "./cache.js";
import { writeStats } from "./stats.js";
import { writeConcordance } from "./concordance.js";
import { transformFilename } from "./transform-filename.js";

const emitLine = (progress, payload) => {
  if (!progress) return;
  process.stdout.write(`${JSON.stringify(payload)}\n`);
};

const buildCacheFromConverted = async (outputDirectory) => {
  const converted = path.join(outputDirectory, "converted_to_docx");
  if (!fs.existsSync(converted)) return null;
  const names = fs
    .readdirSync(converted)
    .filter((file) => file.endsWith(".docx") && !file.startsWith("."))
    .sort();
  if (names.length === 0) return null;

  const files = [];
  for (const name of names) {
    const result = await mammoth.extractRawText({
      path: path.join(converted, name),
    });
    const filename = name.replace(/\.docx$/i, "");
    files.push({
      file: name,
      code: transformFilename(filename),
      paragraphs: paragraphsFromText(result.value),
    });
  }

  writeCache(outputDirectory, files);
  return { files };
};

export const runQuery = async ({
  request,
  outputDirectory,
  exclusionListPath,
  progress = false,
}) => {
  const interpretation = interpret(request);
  if (!interpretation.ok) {
    emitLine(progress, { event: "error", message: interpretation.message });
    console.error(interpretation.message);
    process.exitCode = 1;
    return interpretation;
  }

  let cache = readCache(outputDirectory);
  if (!cache) cache = await buildCacheFromConverted(outputDirectory);
  if (!cache?.files?.length) {
    const message =
      "No hay texto del corpus todavía. Procésalo una vez y vuelve a buscar.";
    emitLine(progress, { event: "error", message });
    console.error(message);
    process.exitCode = 1;
    return interpretation;
  }

  const exclusionList = loadExclusionList(exclusionListPath);
  emitLine(progress, {
    event: "start",
    total: cache.files.length,
    corpus: interpretation.reading,
  });

  const results = [];
  let highlightedTotal = 0;
  let excludedTotal = 0;

  for (const [index, file] of cache.files.entries()) {
    emitLine(progress, {
      event: "begin",
      index: index + 1,
      total: cache.files.length,
      file: file.file,
      code: file.code,
    });

    const gerunds = [];
    for (const [paragraphIndex, paragraph] of (file.paragraphs ?? []).entries()) {
      for (const hit of searchParagraph(
        paragraph.text,
        interpretation,
        exclusionList
      )) {
        gerunds.push({
          ...hit,
          speaker: paragraph.speaker,
          paragraph: paragraphIndex,
        });
      }
    }

    const highlighted = gerunds.filter((hit) => !hit.excluded).length;
    const excluded = gerunds.length - highlighted;
    highlightedTotal += highlighted;
    excludedTotal += excluded;
    results.push({
      file: file.file,
      code: file.code,
      highlighted,
      excluded,
      gerunds,
      failed: false,
    });

    emitLine(progress, {
      event: "file",
      index: index + 1,
      total: cache.files.length,
      file: file.file,
      code: file.code,
      highlighted,
      excluded,
      highlightedTotal,
      excludedTotal,
      words: [
        ...new Set(
          gerunds.filter((hit) => !hit.excluded).map((hit) => hit.word)
        ),
      ].slice(0, 6),
      failed: false,
    });
  }

  writeStats(results, outputDirectory, {
    request,
    reading: interpretation.reading,
    kind: interpretation.kind,
  });
  const concordancePath = writeConcordance(results, outputDirectory, {
    request,
    reading: interpretation.reading,
    kind: interpretation.kind,
  });

  emitLine(progress, {
    event: "done",
    highlighted: highlightedTotal,
    excluded: excludedTotal,
    interviews: results.length,
    concordance: concordancePath,
    reading: interpretation.reading,
    kind: interpretation.kind,
  });

  if (!progress) {
    console.log(
      `${highlightedTotal} resultados. ${interpretation.reading}\n${concordancePath}`
    );
  }

  return interpretation;
};
