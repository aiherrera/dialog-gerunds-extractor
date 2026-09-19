import { formsOf, shouldConjugate } from "./categories.js";

const fold = (value) =>
  value.normalize("NFD").replace(/\p{M}/gu, "").toLowerCase().replace(/\s+/g, " ").trim();

const EXAMPLES =
  "Prueba con gerundios, perífrasis, gerundio predicativo, sustantivos, verbos, o adverbio + gerundio.";

const CATEGORY_ALIASES = [
  ["sustantivo", ["sustantivo", "sustantivos", "nombre", "nombres", "noun", "nouns"]],
  ["adjetivo", ["adjetivo", "adjetivos"]],
  ["adverbio", ["adverbio", "adverbios"]],
  ["verbo", ["verbo", "verbos", "verb", "verbs"]],
  ["gerundio", ["gerundio", "gerundios"]],
  ["infinitivo", ["infinitivo", "infinitivos"]],
  ["participio", ["participio", "participios"]],
  ["pronombre", ["pronombre", "pronombres"]],
  ["preposicion", ["preposicion", "preposiciones"]],
  ["articulo", ["articulo", "articulos", "determinante", "determinantes"]],
  ["conjuncion", ["conjuncion", "conjunciones"]],
];

const CATEGORY_LABEL = {
  sustantivo: "un sustantivo",
  adjetivo: "un adjetivo",
  adverbio: "un adverbio",
  verbo: "un verbo",
  gerundio: "un gerundio",
  infinitivo: "un infinitivo",
  participio: "un participio",
  pronombre: "un pronombre",
  preposicion: "una preposición",
  articulo: "un artículo",
  conjuncion: "una conjunción",
};

const categoryOf = (folded) => {
  for (const [category, aliases] of CATEGORY_ALIASES) {
    if (aliases.includes(folded)) return category;
  }
  return null;
};

const fail = (message = `No entendí esa petición. ${EXAMPLES}`) => ({
  ok: false,
  reading: "",
  kind: "",
  message,
  slots: [],
});

const pieceLabel = (piece) => {
  if (piece.type === "category") return CATEGORY_LABEL[piece.category];
  if (piece.type === "auxiliary") {
    return "un auxiliar (estar, ir, andar, venir, seguir o llevar)";
  }
  if (piece.conjugate) return `el verbo ${piece.lemma}, en sus formas conjugadas`;
  return `la palabra «${piece.lemma}»`;
};

const capitalize = (value) =>
  value ? value.charAt(0).toUpperCase() + value.slice(1) : value;

const parsePiece = (raw) => {
  const trimmed = raw.trim();
  const words = trimmed.split(/\s+/).filter(Boolean);
  if (words.length === 0 || words.length > 2) return null;

  if (words.length === 2) {
    if (fold(words[0]) !== "verbo") return null;
    const lemma = words[1].toLowerCase();
    return {
      type: "lemma",
      lemma,
      conjugate: shouldConjugate(lemma),
      forms: shouldConjugate(lemma) ? formsOf(lemma) : null,
    };
  }

  const folded = fold(words[0]);
  const category = categoryOf(folded);
  if (category) return { type: "category", category };

  const lemma = words[0].toLowerCase();
  const conjugate = shouldConjugate(lemma);
  return {
    type: "lemma",
    lemma,
    conjugate,
    forms: conjugate ? formsOf(lemma) : null,
  };
};

const CONNECTOR =
  /\s+\+\s+|\s+seguido de\s+|\s+antes de\s+|\s+después de\s+|\s+despues de\s+|\s+y\s+/giu;

const parseStructure = (request) => {
  const parts = [];
  const connectors = [];
  let cursor = 0;
  for (const match of request.matchAll(CONNECTOR)) {
    parts.push(request.slice(cursor, match.index));
    connectors.push(fold(match[0]));
    cursor = match.index + match[0].length;
  }
  parts.push(request.slice(cursor));

  const pieces = [];
  for (const part of parts) {
    const piece = parsePiece(part);
    if (!piece) return fail(`No entendí «${part.trim()}». ${EXAMPLES}`);
    pieces.push(piece);
  }
  if (pieces.length === 0) return fail();

  const search = pieces.map((piece) => piece);
  for (let index = 0; index < connectors.length; index += 1) {
    if (connectors[index] === "despues de") {
      const left = search[index];
      search[index] = search[index + 1];
      search[index + 1] = left;
    }
  }

  const readingBits = pieces.map(pieceLabel);
  let reading = capitalize(readingBits[0]);
  for (let index = 1; index < readingBits.length; index += 1) {
    const connector = connectors[index - 1];
    const spoken =
      connector === "seguido de"
        ? "seguido de"
        : connector === "antes de"
          ? "antes de"
          : connector === "despues de"
            ? "después de"
            : "seguido de";
    reading += `, ${spoken} ${readingBits[index]}`;
  }

  return {
    ok: true,
    kind: "estructura",
    reading: `${reading}.`,
    message: "",
    slots: search,
  };
};

export const interpret = (request) => {
  const trimmed = String(request ?? "").trim();
  const folded = fold(trimmed);
  if (!folded) return fail("Escribe lo que quieres buscar.");

  if (folded === "gerundio" || folded === "gerundios") {
    return {
      ok: true,
      kind: "gerundios",
      reading: "Gerundios en -ando, -iendo o -yendo, con o sin pronombre.",
      message: "",
      slots: [],
    };
  }

  if (
    folded === "perifrasis" ||
    folded === "perifrasis verbal" ||
    folded === "perifrasis de gerundio"
  ) {
    return {
      ok: true,
      kind: "perifrasis",
      reading:
        "Un auxiliar (estar, ir, andar, venir, seguir o llevar), en sus formas conjugadas, seguido de un gerundio.",
      message: "",
      slots: [
        { type: "auxiliary" },
        { type: "category", category: "gerundio" },
      ],
    };
  }

  if (
    folded === "gerundio predicativo" ||
    folded === "gerundio-predicativo" ||
    folded === "gerundio atributivo"
  ) {
    const ser = formsOf("ser");
    return {
      ok: true,
      kind: "predicativo",
      reading: "El verbo ser, en sus formas conjugadas, seguido de un gerundio.",
      message: "",
      slots: [
        { type: "lemma", lemma: "ser", conjugate: true, forms: ser },
        { type: "category", category: "gerundio" },
      ],
    };
  }

  if (["sustantivo", "sustantivos", "nombre", "nombres", "noun", "nouns"].includes(folded)) {
    return {
      ok: true,
      kind: "sustantivos",
      reading: "Sustantivos.",
      message: "",
      slots: [{ type: "category", category: "sustantivo" }],
    };
  }

  if (["verbo", "verbos", "verb", "verbs"].includes(folded)) {
    return {
      ok: true,
      kind: "verbos",
      reading: "Verbos.",
      message: "",
      slots: [{ type: "category", category: "verbo" }],
    };
  }

  const word = trimmed.match(/^(?:la\s+|el\s+)?(?:palabra|forma)\s+(.+)$/iu);
  if (word) {
    const lemma = word[1].trim().toLowerCase();
    if (!lemma || /\s/.test(lemma)) return fail(`No entendí «${word[1].trim()}». ${EXAMPLES}`);
    return {
      ok: true,
      kind: "forma",
      reading: `La palabra «${lemma}».`,
      message: "",
      slots: [{ type: "lemma", lemma, conjugate: false, forms: null }],
    };
  }

  const ending = trimmed.match(/^(?:termina en|terminación|terminacion)\s+[-–]?\s*(.+)$/iu);
  if (ending) {
    const suffix = ending[1].trim().toLowerCase().replace(/^[-–]/, "");
    if (!suffix || /\s/.test(suffix)) return fail();
    return {
      ok: true,
      kind: "terminacion",
      reading: `Palabras que terminan en «${suffix}».`,
      message: "",
      slots: [{ type: "ending", ending: suffix }],
    };
  }

  return parseStructure(trimmed);
};
