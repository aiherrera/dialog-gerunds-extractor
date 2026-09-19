// Spanish gerunds end in -ando, -iendo, or -yendo, including the accented
// forms used when an enclitic pronoun is attached (dándole, haciéndome).
// Longer pronouns come first so "los" is not read as "lo".
const GERUND_SOURCE =
  String.raw`(?<![\p{L}])([\p{L}]*?(?:ando|iendo|yendo|ándo|iéndo|yéndo)(?:los|las|les|nos|os|me|te|se|lo|la|le)*)(?![\p{L}])`;

export const gerundRegex = new RegExp(GERUND_SOURCE, "giu");

const letterPattern = /\p{L}/u;
const parsedGerundPattern =
  /^(.*?)(ando|iendo|yendo|ándo|iéndo|yéndo)((?:los|las|les|nos|os|me|te|se|lo|la|le)*)$/iu;

// Transcription tags sometimes sit inside a word: conversa<alargamiento/>ndo.
// Drop only a tag that is glued to letters on both sides, and remember where
// each remaining character came from so highlights can cover the original span.
export const normalizeForMatch = (text) => {
  let normalized = "";
  const originalIndexes = [];

  for (let index = 0; index < text.length; ) {
    if (text[index] === "<") {
      const tagEnd = text.indexOf(">", index + 1);
      const previousIsLetter =
        normalized.length > 0 && letterPattern.test(normalized.at(-1));
      const nextCharacter = tagEnd === -1 ? "" : text[tagEnd + 1] ?? "";
      const nextIsLetter = letterPattern.test(nextCharacter);
      const tagHasNewline =
        tagEnd !== -1 && text.slice(index, tagEnd).includes("\n");

      if (tagEnd !== -1 && previousIsLetter && nextIsLetter && !tagHasNewline) {
        index = tagEnd + 1;
        continue;
      }
    }

    originalIndexes.push(index);
    normalized += text[index];
    index += 1;
  }

  return { normalized, originalIndexes };
};

export const findGerunds = (text, exclusionList) => {
  const { normalized, originalIndexes } = normalizeForMatch(text);
  const regex = new RegExp(GERUND_SOURCE, "giu");
  const found = [];

  for (const match of normalized.matchAll(regex)) {
    const word = match[0];
    const start = originalIndexes[match.index];
    const end = originalIndexes[match.index + word.length - 1] + 1;
    const parsed = word.match(parsedGerundPattern);
    const ending = parsed?.[2] ?? "";
    const clitic = parsed?.[3] ?? "";
    const crossesTag = end - start > word.length;
    const unaccentedCliticAcrossTag =
      clitic !== "" && !/[áéíóú]/iu.test(ending) && crossesTag;

    // grandote split as grando<alargamiento/>te is not a gerund plus pronoun.
    // A real pronoun on a gerund carries an accent (dándote), unless the
    // whole word was already written together (haciendole).
    if (unaccentedCliticAcrossTag) continue;

    found.push({
      word,
      excluded: exclusionList.has(word.toLowerCase()),
      start,
      end,
      ending,
      clitic,
      crossesTag,
    });
  }

  return found;
};
