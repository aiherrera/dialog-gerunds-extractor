import fs from "fs";
import path from "path";
import { pathToFileURL } from "url";
import mammoth from "mammoth";
import { findGerunds } from "./gerunds.js";
import { loadExclusionList } from "./exclusion-list.js";

const isDirectRun =
  process.argv[1] &&
  import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href;

export const collectGerunds = async (directoryPath, exclusionListPath) => {
  const exclusionList = loadExclusionList(exclusionListPath);
  const files = fs
    .readdirSync(directoryPath)
    .filter((file) => file.endsWith(".docx") && !file.startsWith("."));

  const counts = new Map();

  for (const file of files) {
    const result = await mammoth.extractRawText({
      path: path.join(directoryPath, file),
    });

    for (const gerund of findGerunds(result.value, exclusionList)) {
      if (gerund.excluded) continue;
      const key = gerund.word.toLowerCase();
      counts.set(key, (counts.get(key) ?? 0) + 1);
    }
  }

  return counts;
};

if (isDirectRun) {
  const directoryPath = process.argv[2] ?? "./output/converted_to_docx";
  const exclusionListPath =
    process.argv[3] ?? path.join("utils", "exclusion_list.txt");
  const outputPath = process.argv[4] ?? "output/gerunds.txt";

  const counts = await collectGerunds(directoryPath, exclusionListPath);
  const lines = [...counts.entries()]
    .sort((left, right) => right[1] - left[1] || left[0].localeCompare(right[0]))
    .map(([word, count]) => `${count}\t${word}`);

  fs.mkdirSync(path.dirname(outputPath), { recursive: true });
  fs.writeFileSync(outputPath, `${lines.join("\n")}\n`);
  console.log(`Wrote ${lines.length} gerund types to ${outputPath}`);
}
