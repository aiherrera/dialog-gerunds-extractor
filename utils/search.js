import { auxiliaryForms, categoriesFor, LEXICAL } from "./categories.js";
import { findGerunds, normalizeForMatch } from "./gerunds.js";

const contextAround = (text, start, end, radius = 72) => {
  let left = Math.max(0, start - radius);
  let right = Math.min(text.length, end + radius);

  if (left > 0) {
    const space = text.indexOf(" ", left);
    if (space !== -1 && space < start) left = space + 1;
  }

  if (right < text.length) {
    const space = text.lastIndexOf(" ", right);
    if (space > end) right = space;
  }

  const tidy = (value) => value.replace(/\s+/g, " ");

  return {
    before: tidy(text.slice(left, start)).replace(/^\s+/, ""),
    match: text.slice(start, end),
    after: tidy(text.slice(end, right)).replace(/\s+$/, ""),
  };
};

const tokenize = (text) => {
  const { normalized, originalIndexes } = normalizeForMatch(text);
  const pattern = /[\p{L}_]+|\/+/gu;
  const tokens = [];

  for (const match of normalized.matchAll(pattern)) {
    const surface = match[0];
    const start = originalIndexes[match.index];
    const end = originalIndexes[match.index + surface.length - 1] + 1;
    tokens.push({
      surface,
      lower: surface.toLowerCase(),
      start,
      end,
      barrier: surface.startsWith("/"),
      categories: surface.startsWith("/") ? new Set() : categoriesFor(surface),
    });
  }

  return tokens;
};

const slotMatches = (token, slot, exclusionList) => {
  if (token.barrier) return false;

  if (slot.type === "auxiliary") {
    return auxiliaryForms().has(token.lower);
  }

  if (slot.type === "ending") {
    return token.lower.endsWith(slot.ending) && !exclusionList.has(token.lower);
  }

  if (slot.type === "lemma") {
    if (slot.conjugate) return slot.forms.has(token.lower);
    return token.lower === slot.lemma && !exclusionList.has(token.lower);
  }

  if (!token.categories.has(slot.category)) return false;
  if (LEXICAL.has(slot.category) && exclusionList.has(token.lower)) return false;
  return true;
};

const matchAt = (tokens, start, slots, exclusionList) => {
  let pos = start;
  for (let index = 0; index < slots.length; index += 1) {
    if (index === 0) {
      if (!slotMatches(tokens[pos], slots[index], exclusionList)) return null;
      pos += 1;
      continue;
    }

    let placed = false;
    for (let gap = 0; gap <= 2; gap += 1) {
      const at = pos + gap;
      if (at >= tokens.length) break;
      let blocked = false;
      for (let cursor = pos; cursor < at; cursor += 1) {
        if (tokens[cursor].barrier) blocked = true;
      }
      if (blocked) break;
      if (slotMatches(tokens[at], slots[index], exclusionList)) {
        pos = at + 1;
        placed = true;
        break;
      }
    }
    if (!placed) return null;
  }

  const first = tokens[start];
  const last = tokens[pos - 1];
  return { start: first.start, end: last.end, next: pos };
};

const record = (text, start, end, extra) => ({
  word: text.slice(start, end).toLowerCase().replace(/\s+/g, " "),
  excluded: false,
  ending: "",
  clitic: "",
  crossesTag: text.slice(start, end).includes("<"),
  ...contextAround(text, start, end),
  ...extra,
});

export const searchParagraph = (text, interpretation, exclusionList) => {
  if (!interpretation?.ok) return [];

  if (interpretation.kind === "gerundios") {
    return findGerunds(text, exclusionList).map((gerund) => ({
      word: gerund.word.toLowerCase(),
      excluded: gerund.excluded,
      ending: gerund.ending,
      clitic: gerund.clitic,
      crossesTag: gerund.crossesTag,
      ...contextAround(text, gerund.start, gerund.end),
    }));
  }

  const tokens = tokenize(text);
  const found = [];
  for (let index = 0; index < tokens.length; ) {
    if (tokens[index].barrier) {
      index += 1;
      continue;
    }
    const hit = matchAt(tokens, index, interpretation.slots, exclusionList);
    if (!hit) {
      index += 1;
      continue;
    }
    found.push(record(text, hit.start, hit.end));
    index = hit.next;
  }
  return found;
};
