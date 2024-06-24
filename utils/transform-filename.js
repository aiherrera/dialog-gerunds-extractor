export const transformFilename = (filename) => {
  // Use a regular expression to match the pattern
  const regex = /^[0-9]+ ([A-Z]+_[A-Z0-9]+_[0-9]+)/i;
  // Execute the regex on the filename
  const match = filename.match(regex);
  // If there's a match, return the first capture group; otherwise, return the original filename
  return match ? match[1] : filename;
};
