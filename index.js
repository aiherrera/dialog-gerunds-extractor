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

fs.readdir(corpusDirectory, async (err, files) => {
  if (err) {
    console.error("Error reading the folder:", err);
    return;
  }

  // Filter out hidden files/directories (starting with '.DS_Store' etc)
  const visibleFiles = files.filter((file) => !file.startsWith("."));

  // Now loop through the visibleFiles array
  for (const file of visibleFiles) {
    // Process all files, not just .doc|.rtf
    const documentPath = path.join(corpusDirectory, file);
    const filename = file.replace(/\.(doc|rtf|docx)$/i, "");
    const convertedDocumentPath = path.join(
      convertedOutputDirectory,
      `${filename}.docx`
    );

    try {
      // Handle .doc and .rtf files
      if (file.match(/\.(doc|rtf)$/i)) {
        await convertDocToDocxWithLibreOffice(
          documentPath,
          convertedOutputDirectory
        );
      }
      // Handle .docx files
      else if (file.match(/\.(docx)$/i)) {
        fs.copyFileSync(documentPath, convertedDocumentPath);
      }

      // Generate a docx file with highlighted gerunds (for all files)
      const metadata = {
        creator: "Alain Iglesias",
        title: filename,
        description: "Periphrastic Gerunds highlighted in document",
      };

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
    } catch (error) {
      console.error("Error processing file:", error);
    }
  }
});
