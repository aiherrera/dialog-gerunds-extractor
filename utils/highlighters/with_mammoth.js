import mammoth from "mammoth";
import fs from "fs";
import path from "path";
import { REGEX } from "../index.js";

export const convertAndHighlightToMarkdown = async (
  inputFilePath,
  outputDirectory
) => {
  try {
    const result = await mammoth.extractRawText({ path: inputFilePath });
    let modifiedText = result.value;

    // Find all gerund matches and replace with highlighted markdown
    modifiedText = modifiedText.replace(REGEX.gerundRegex, (match) => {
      // Check if the match is in the exclusion list
      if (exclusionList.has(match.toLowerCase())) {
        return `<span>${match}</span>`;
      } else {
        return `${match}`;
      }
    });

    // Create the full output file path
    const fileName =
      path.basename(inputFilePath, path.extname(inputFilePath)) + ".md";
    const outputFilePath = path.join(outputDirectory, fileName);

    fs.writeFileSync(outputFilePath, modifiedText);
    console.log(`Highlighted gerunds in: ${outputFilePath}`);
  } catch (error) {
    console.error("Error processing document:", error);
  }
};

// const inputDocxPath = "./corpus/converted_docx/001 LHAB_H11_001 CON E.docx";
// const outputMarkdownPath = "./highlighted_gerunds.md";

// highlightGerundsInDocx(inputDocxPath, outputMarkdownPath);
