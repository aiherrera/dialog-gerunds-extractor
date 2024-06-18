import fs from "fs";
import path from "path";
import { exec } from "child_process";

export const dismissDialog = () => {
  const appleScript = `
    tell application "System Events"
      tell process "Microsoft Word"
        repeat while exists (windows where name contains "Warning")
          click button "OK" of first window where name contains "Warning"
          delay 1.5 -- Adjust the delay as needed
        end repeat
      end tell
    end tell
  `;

  exec(`osascript -e '${appleScript}'`, (err, stdout, stderr) => {
    if (err) {
      console.error("Error executing AppleScript:", stderr);
    } else {
      console.log("Dialog dismissed if it existed");
    }
  });
};

export const convertDocToDocxWithLibreOffice = (
  documentPath,
  convertedOutputDirectory
) => {
  return new Promise((resolve, reject) => {
    const docxPath = path.join(
      convertedOutputDirectory,
      path.basename(documentPath).replace(/\.(doc|rtf)$/i, ".docx")
    );
    // Construct the LibreOffice convert command
    const command = `soffice --headless --convert-to docx --outdir "${convertedOutputDirectory}" "${documentPath}"`;

    exec(command, (error, stdout, stderr) => {
      if (error) {
        console.error(`Error converting ${documentPath}: ${stderr}`);
        reject(error);
      } else {
        console.log(`Converted ${documentPath} to ${docxPath}`);
        resolve(docxPath);
        dismissDialog();
      }
    });
  });
};

export const convertAllDocFilesInFolder = async (
  folderPath,
  convertedOutputDirectory
) => {
  fs.readdir(folderPath, async (err, files) => {
    if (err) {
      console.error("Error reading the folder:", err);
      return;
    }

    // Filter for .doc files
    const docFiles = files.filter((file) => file.match(/\.(doc|rtf)$/i));

    for (const file of docFiles) {
      const documentPath = path.join(folderPath, file);
      // Convert each .doc file to .docx
      try {
        await convertDocToDocxWithLibreOffice(
          documentPath,
          convertedOutputDirectory
        );
      } catch (conversionError) {
        console.error("Conversion error:", conversionError);
      }
    }
  });
};
