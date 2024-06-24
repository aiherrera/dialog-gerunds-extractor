import fs from "fs";
import path from "path";
import mammoth from "mammoth";
import { Document, Packer, Paragraph, TextRun } from "docx";
import { REGEX, loadExclusionList, transformFilename } from "../index.js";

export const highlightGerundsInDocx = async (
  inputFilePath,
  outputDirectory,
  exclusionListPath,
  ...props
) => {
  try {
    const exclusionList = loadExclusionList(exclusionListPath);

    // const text = fs.readFileSync(inputFilePath, "utf-8");
    const result = await mammoth.extractRawText({ path: inputFilePath });
    let modifiedText = result.value;

    const paragraphs = modifiedText.split("\n").filter((p) => p.trim() !== "");

    const doc = new Document({
      props,
      sections: [
        {
          properties: {},
          children: paragraphs.map((paragraphText, index) => {
            const runs = [];
            let lastIndex = 0;
            let match = "";

            while ((match = REGEX.gerundRegex.exec(paragraphText))) {
              runs.push(
                new TextRun(paragraphText.slice(lastIndex, match.index))
              );

              // Check if the match is in the exclusion list
              if (!exclusionList.has(match[0].toLowerCase())) {
                runs.push(
                  new TextRun({
                    text: match[0],
                    color: "FF0000", // Red color for highlighted gerunds
                  })
                );
              } else {
                runs.push(
                  new TextRun({
                    text: match[0],
                  })
                );
              }
              lastIndex = REGEX.gerundRegex.lastIndex;
            }

            runs.push(new TextRun(paragraphText.slice(lastIndex)));

            // Add a line break after each paragraph except the last
            if (index < paragraphs.length - 1) {
              runs.push(new TextRun({ break: 1 }));
            }

            return new Paragraph({ children: runs });
          }),
        },
      ],
    });

    // Create the full output file path
    const fileName = path.basename(inputFilePath, path.extname(inputFilePath));
    //NOTE - The transformFilename function is used to clean up the filename
    const fixedFileName = transformFilename(fileName) + ".docx";

    const outputFilePath = path.join(outputDirectory, fixedFileName);

    const buffer = await Packer.toBuffer(doc);
    fs.writeFileSync(outputFilePath, buffer);
  } catch (error) {
    console.error("Error processing document:", error);
  }
};

// Example usage (remove if you are calling from index.js):
// const inputFilePath = "./corpus/converted_to_docx/001 LHAB_H11_001 CON E.docx";
// const outputDirectory = "./output/";

// highlightGerundsInDocx(inputFilePath, outputDirectory, {
//  creator: "Your Name",
//  // ... other document properties
// });
