import fs from "fs";
import path from "path";
import { exec } from "child_process";

const corpusDirectory = path.join(__dirname, "corpus");
const convertedDirectory = path.join(corpusDirectory, "converted_docx");
const appleScriptPath = path.join(
  __dirname,
  "utils",
  "convertDocToDocx.applescript"
);

// Ensure the converted_docx directory exists
if (!fs.existsSync(convertedDirectory)) {
  fs.mkdirSync(convertedDirectory);
}

const convertDocToDocxWithWord = (docPath, convertedFolderPath) => {
  return new Promise((resolve, reject) => {
    const docxPath = path.join(
      convertedFolderPath,
      path.basename(docPath).replace(/\.doc$/i, ".docx")
    );
    const command = `osascript "${appleScriptPath}" "${docPath}" "${docxPath}"`;

    exec(command, (error) => {
      if (error) {
        console.error(`Error converting ${docPath} to .docx:`, error);
        reject(error);
      } else {
        console.log(`Converted ${docPath} to ${docxPath}`);
        resolve(docxPath);
      }
    });
  });
};

const convertAllDocFilesInFolder = async (folderPath) => {
  fs.readdir(folderPath, async (err, files) => {
    if (err) {
      console.error("Error reading the folder:", err);
      return;
    }

    // Filter for .doc files
    const docFiles = files.filter((file) => file.endsWith(".doc"));

    for (const file of docFiles) {
      const docPath = path.join(folderPath, file);
      // Convert each .doc file to .docx
      try {
        await convertDocToDocxWithWord(docPath, convertedDirectory);
      } catch (conversionError) {
        console.error("Conversion error:", conversionError);
      }
    }
  });
};

// Start the conversion process
convertAllDocFilesInFolder(corpusDirectory);
