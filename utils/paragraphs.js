const speakerPattern = /^(I|E|O|V)\.?\s*:/i;

export const paragraphsFromText = (text) => {
  const paragraphs = [];
  let speaker = "untagged";

  for (const line of String(text).split("\n")) {
    const speakerMatch = line.match(speakerPattern);
    if (speakerMatch) speaker = speakerMatch[1].toUpperCase();
    if (line.trim() === "") continue;
    paragraphs.push({ text: line, speaker });
  }

  return paragraphs;
};
