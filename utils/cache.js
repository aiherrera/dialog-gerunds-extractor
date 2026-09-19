import fs from "fs";
import path from "path";

export const cacheFile = (outputDirectory) =>
  path.join(outputDirectory, "cache", "interviews.json");

export const readCache = (outputDirectory) => {
  const file = cacheFile(outputDirectory);
  if (!fs.existsSync(file)) return null;
  return JSON.parse(fs.readFileSync(file, "utf8"));
};

export const writeCache = (outputDirectory, files) => {
  const file = cacheFile(outputDirectory);
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, JSON.stringify({ files }));
  return file;
};
