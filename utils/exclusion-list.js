import fs from "fs";

export const loadExclusionList = (filePath) => {
  const list = fs.readFileSync(filePath, "utf-8").split("\n");
  return new Set(list.map((word) => word.trim().toLowerCase()));
};
