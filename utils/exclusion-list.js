import fs from "fs";

export const loadExclusionList = (filePath) => {
  const list = fs.readFileSync(filePath, "utf-8").split(/\r?\n/);
  return new Set(
    list.map((word) => word.trim().toLowerCase()).filter((word) => word !== "")
  );
};
