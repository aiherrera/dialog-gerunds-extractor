import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import mammoth from "mammoth";
import { findGerunds } from "../gerunds.js";
import { loadExclusionList } from "../exclusion-list.js";

const defaultExclusionListPath = path.join(
  path.dirname(fileURLToPath(import.meta.url)),
  "..",
  "exclusion_list.txt"
);

export const convertAndHighlightToMarkdown = async (
  inputFilePath,
  outputDirectory,
  exclusionListPath = defaultExclusionListPath
) => {
  const exclusionList = loadExclusionList(exclusionListPath);
  const result = await mammoth.extractRawText({ path: inputFilePath });
  let highlightedMarkdown = "";
  let cursor = 0;

  for (const gerund of findGerunds(result.value, exclusionList)) {
    highlightedMarkdown += result.value.slice(cursor, gerund.start);
    const text = result.value.slice(gerund.start, gerund.end);
    highlightedMarkdown += gerund.excluded ? text : `**${text}**`;
    cursor = gerund.end;
  }

  highlightedMarkdown += result.value.slice(cursor);

  const fileName = `${path.basename(inputFilePath, path.extname(inputFilePath))}.md`;
  const outputFilePath = path.join(outputDirectory, fileName);
  fs.mkdirSync(outputDirectory, { recursive: true });
  fs.writeFileSync(outputFilePath, highlightedMarkdown);

  return outputFilePath;
};
