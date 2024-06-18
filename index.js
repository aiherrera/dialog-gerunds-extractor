import path from "path";
import fs from "fs";
import { fileURLToPath } from "url";

import { convertDocToDocxWithLibreOffice } from "./utils/index.js";
import { highlightGerundsInDocx } from "./utils/index.js";

/**
 * Since we are using ESM modules, we need to use the fileURLToPath function
 * to get the __filename and then use the path module to get the __dirname.
 */
// Get the __filename
const __filename = fileURLToPath(import.meta.url);
// Get the __dirname
const __dirname = path.dirname(__filename);

// Database of documents (original corpus)
const corpusDirectory = path.join(__dirname, "corpus");
// output for converted documents (doc to docx | rtf to docx)
const convertedOutputDirectory = path.join(
  __dirname,
  "output",
  "converted_to_docx"
);
// output for highlighted documents (regex matched gerunds in docx files)
const highlightedOutputDirectory = path.join(
  __dirname,
  "output",
  "highlighted"
);

if (!fs.existsSync(corpusDirectory)) {
  fs.mkdirSync(corpusDirectory, { recursive: true });
}

// Ensure the output folder exist
if (!fs.existsSync(convertedOutputDirectory)) {
  fs.mkdirSync(convertedOutputDirectory, { recursive: true });
}

// Ensure the output folder exist
if (!fs.existsSync(highlightedOutputDirectory)) {
  fs.mkdirSync(highlightedOutputDirectory, { recursive: true });
}

// convertAllDocFilesInFolder(corpusDirectory, convertedOutputDirectory);
fs.readdir(corpusDirectory, async (err, files) => {
  if (err) {
    console.error("Error reading the folder:", err);
    return;
  }

  // Filter for .doc|.rtf files
  const docFiles = files.filter((file) => file.match(/\.(doc|rtf)$/i));

  for (const file of docFiles) {
    const documentPath = path.join(corpusDirectory, file);
    try {
      // Convert each .doc|.rtf file to .docx
      await convertDocToDocxWithLibreOffice(
        documentPath,
        convertedOutputDirectory
      );

      const filename = file.replace(/\.(doc|rtf)$/i, "");

      // generate a docx file from the highlighted markdown file
      const metadata = {
        creator: "Alain Iglesias",
        title: file.replace(/\.(doc|rtf)$/i, ""),
        description: "Periphrastic Gerunds highlighted in document",
      };

      const convertedDocumentPath = path.join(
        convertedOutputDirectory,
        `${filename}.docx`
      );
      const exclusionListPath = path.join(
        __dirname,
        "utils",
        "exclusion_list.txt"
      );
      await highlightGerundsInDocx(
        convertedDocumentPath,
        highlightedOutputDirectory,
        exclusionListPath,
        metadata
      );
    } catch (conversionError) {
      console.error("Conversion error:", conversionError);
    }
  }
});
