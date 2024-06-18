import fs from "fs";
import path from "path";

export const readDocumentsFromDirectory = (directoryPath) => {
  return new Promise((resolve, reject) => {
    fs.readdir(directoryPath, (err, files) => {
      if (err) {
        reject(err);
      } else {
        const documentFiles = files
          .filter((file) => file.endsWith(".docx"))
          .map((file) => path.join(directoryPath, file));
        resolve(documentFiles);
      }
    });
  });
};
