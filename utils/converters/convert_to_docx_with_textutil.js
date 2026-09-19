import path from "path";
import { execFile } from "child_process";
import { promisify } from "util";

const execFileAsync = promisify(execFile);

export const convertToDocxWithTextutil = async (
  documentPath,
  convertedOutputDirectory
) => {
  if (process.platform !== "darwin") {
    throw new Error(
      "Converting .doc and .rtf requires textutil, which is included with macOS."
    );
  }

  const filename = path
    .basename(documentPath)
    .replace(/\.(doc|rtf|docx)$/i, "");
  const outputPath = path.join(convertedOutputDirectory, `${filename}.docx`);

  await execFileAsync("textutil", [
    "-convert",
    "docx",
    "-output",
    outputPath,
    documentPath,
  ]);

  return outputPath;
};
