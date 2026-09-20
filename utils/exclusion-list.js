import fs from "fs";

export const loadExclusionList = (filePath) => {
  if (!filePath || !fs.existsSync(filePath)) return new Set();
  const list = fs.readFileSync(filePath, "utf-8").split(/\r?\n/);
  return new Set(
    list.map((word) => word.trim().toLowerCase()).filter((word) => word !== "")
  );
};
