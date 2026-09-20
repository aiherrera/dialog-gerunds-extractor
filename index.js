import path from "path";
import { copyFile, mkdir, readdir } from "fs/promises";
import { fileURLToPath } from "url";

import { convertToDocxWithTextutil } from "./utils/converters/convert_to_docx_with_textutil.js";
import { highlightGerundsInDocx } from "./utils/highlighters/with_docx_highlight.js";
import { transformFilename } from "./utils/transform-filename.js";
import { writeStats } from "./utils/stats.js";
import { writeConcordance } from "./utils/concordance.js";
import { writeCache } from "./utils/cache.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const args = process.argv.slice(2);
const hasFlag = (name) => args.includes(name);
const option = (name, fallback) => {
  const index = args.indexOf(name);
  if (index === -1) return fallback;
  const value = args[index + 1];
  if (!value || value.startsWith("--")) return fallback;
  return value;
};

const progress = hasFlag("--progress");
const corpusDirectory = path.resolve(
  option("--corpus", path.join(__dirname, "corpus"))
);
const outputDirectory = path.resolve(
  option("--output", path.join(__dirname, "output"))
);
const convertedOutputDirectory = path.join(outputDirectory, "converted_to_docx");
const highlightedOutputDirectory = path.join(outputDirectory, "highlighted");
const exclusionListPath = path.resolve(
  option("--exclusions", path.join(__dirname, "utils", "exclusion_list.txt"))
);

const emit = (payload) => {
  if (!progress) return;
  process.stdout.write(`${JSON.stringify(payload)}\n`);
};

const say = (line) => {
  if (!progress) console.log(line);
};

if (!hasFlag("--corpus")) {
  await mkdir(corpusDirectory, { recursive: true });
}
await mkdir(convertedOutputDirectory, { recursive: true });
await mkdir(highlightedOutputDirectory, { recursive: true });

let files;
try {
  files = (await readdir(corpusDirectory))
    .filter((file) => !file.startsWith("."))
    .filter((file) => /\.(doc|rtf|docx)$/i.test(file))
    .sort();
} catch (error) {
  const message = `No pude abrir el corpus. ${error.message}`;
  emit({ event: "error", message });
  console.error(message);
  process.exit(1);
}

if (files.length === 0) {
  const message = `No hay archivos .doc, .docx o .rtf en ${corpusDirectory}`;
  emit({ event: "error", message });
  console.error(message);
  process.exit(1);
}

emit({ event: "start", total: files.length, corpus: corpusDirectory });
say("highlighted  excluded  informant  interviewer  interview");

const results = [];
const cacheFiles = [];
let highlightedTotal = 0;
let excludedTotal = 0;

for (const [index, file] of files.entries()) {
  const documentPath = path.join(corpusDirectory, file);
  const filename = file.replace(/\.(doc|rtf|docx)$/i, "");
  const convertedDocumentPath = path.join(
    convertedOutputDirectory,
    `${filename}.docx`
  );
  const code = transformFilename(filename);

  emit({
    event: "begin",
    index: index + 1,
    total: files.length,
    file,
    code,
  });

  try {
    if (/\.(doc|rtf)$/i.test(file)) {
      await convertToDocxWithTextutil(documentPath, convertedOutputDirectory);
    } else {
      await copyFile(documentPath, convertedDocumentPath);
    }

    const { highlighted, excluded, gerunds, paragraphs } = await highlightGerundsInDocx(
      convertedDocumentPath,
      highlightedOutputDirectory,
      exclusionListPath,
      {
        creator: "Alain Iglesias",
        title: filename,
        description: "Periphrastic gerunds highlighted in document",
      }
    );

    results.push({ file, code, highlighted, excluded, gerunds, failed: false });
    cacheFiles.push({ file, code, paragraphs });
    const informant = gerunds.filter(
      (gerund) => !gerund.excluded && gerund.speaker === "I"
    ).length;
    const interviewer = gerunds.filter(
      (gerund) => !gerund.excluded && gerund.speaker === "E"
    ).length;
    highlightedTotal += highlighted;
    excludedTotal += excluded;

    const words = [];
    const seen = new Set();
    for (const gerund of gerunds) {
      if (gerund.excluded || seen.has(gerund.word)) continue;
      seen.add(gerund.word);
      words.push(gerund.word);
      if (words.length === 6) break;
    }

    say(
      `${String(highlighted).padStart(11)}  ${String(excluded).padStart(8)}  ${String(informant).padStart(9)}  ${String(interviewer).padStart(11)}  ${code}`
    );
    emit({
      event: "file",
      index: index + 1,
      total: files.length,
      file,
      code,
      highlighted,
      excluded,
      informant,
      interviewer,
      highlightedTotal,
      excludedTotal,
      words,
      failed: false,
    });
  } catch (error) {
    results.push({
      file,
      code,
      highlighted: 0,
      excluded: 0,
      gerunds: [],
      failed: true,
    });
    const message = error instanceof Error ? error.message : String(error);
    if (!progress) console.error(`Error processing ${file}:`, message);
    emit({
      event: "file",
      index: index + 1,
      total: files.length,
      file,
      code,
      highlighted: 0,
      excluded: 0,
      highlightedTotal,
      excludedTotal,
      words: [],
      failed: true,
      message,
    });
  }
}

const { summary, statsPath, typePath, filePath } = writeStats(
  results,
  outputDirectory,
  {
    request: "gerundios",
    reading: "Gerundios en -ando, -iendo o -yendo, con o sin pronombre.",
    kind: "gerundios",
  }
);
const concordancePath = writeConcordance(results, outputDirectory, {
  request: "gerundios",
  reading: "Gerundios en -ando, -iendo o -yendo, con o sin pronombre.",
  kind: "gerundios",
});
if (cacheFiles.length > 0) writeCache(outputDirectory, cacheFiles);

emit({
  event: "done",
  highlighted: highlightedTotal,
  excluded: excludedTotal,
  interviews: results.length,
  concordance: concordancePath,
});

say(`\n${summary}\n`);
say(
  `Stats written to\n  ${statsPath}\n  ${typePath}\n  ${filePath}\n  ${concordancePath}`
);
