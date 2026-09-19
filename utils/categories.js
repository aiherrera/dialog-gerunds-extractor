import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { findGerunds } from "./gerunds.js";

const dir = path.join(path.dirname(fileURLToPath(import.meta.url)), "lexicon");

const fold = (value) =>
  value.normalize("NFD").replace(/\p{M}/gu, "").toLowerCase();

const loadList = (name) => {
  const file = path.join(dir, `${name}.txt`);
  if (!fs.existsSync(file)) return new Set();
  return new Set(
    fs
      .readFileSync(file, "utf8")
      .split(/\r?\n/)
      .map((word) => word.trim().toLowerCase())
      .filter(Boolean)
  );
};

const NOUNS = loadList("sustantivos");
const ADJECTIVES = loadList("adjetivos");
const VERBS = loadList("verbos");
const ADVERBS = loadList("adverbios");

const ARTICLES = new Set(
  "el la los las un una unos unas lo al del".split(" ")
);
const PREPOSITIONS = new Set(
  "a ante bajo con contra de desde durante en entre hacia hasta mediante para por según segun sin sobre tras vía via excepto salvo".split(
    " "
  )
);
const PRONOUNS = new Set(
  "yo tú tu usted ustedes él el ella nosotros nosotras vosotros vosotras ellos ellas me te se nos os le les lo la los las mí mi ti sí si conmigo contigo consigo mío mio mía mia míos mios mías mias tuyo tuya tuyos tuyas suyo suya suyos suyas nuestro nuestra nuestros nuestras vuestro vuestra vuestros vuestras este esta estos estas ese esa esos esas aquel aquella aquellos aquellas esto eso aquello que quien quienes cual cuales cuyo cuya cuyos cuyas algo alguien nada nadie todo toda todos todas".split(
    " "
  )
);
const CONJUNCTIONS = new Set(
  "y e ni o u pero mas sino que porque pues aunque si como cuando mientras donde entonces".split(
    " "
  )
);

const NON_INFINITIVES = new Set(
  "mujer lugar azúcar azucar dolor color amor señor senor calor mayor menor mejor peor cualquier hogar pajar taller poderio".split(
    " "
  )
);

const IRREGULARS = {
  estar: "estar estoy estás estas está esta estamos estáis estais están estan estaba estabas estábamos estabamos estabais estaban estuve estuviste estuvo estuvimos estuvisteis estuvieron estado estando esté este estés estes estemos estéis esteis estén esten".split(
    " "
  ),
  ser: "ser soy eres es somos sois son era eras éramos eramos erais eran fui fuiste fue fuimos fuisteis fueron sido siendo sea seas seamos seáis seais sean".split(
    " "
  ),
  ir: "ir voy vas va vamos vais van iba ibas íbamos ibamos ibais iban fui fuiste fue fuimos fuisteis fueron yendo ido vaya vayas vayamos vayáis vayais vayan".split(
    " "
  ),
  andar:
    "andar ando andas anda andamos andáis andais andan andaba andabas andábamos andabamos andabais andaban anduve anduviste anduvo anduvimos anduvisteis anduvieron andando andado".split(
      " "
    ),
  venir:
    "venir vengo vienes viene venimos venís venis vienen venía venia venías venias veníamos veniamos veníais veniais venían venian vine viniste vino vinimos vinisteis vinieron viniendo venido".split(
      " "
    ),
  seguir:
    "seguir sigo sigues sigue seguimos seguís seguis siguen seguía seguia seguías seguías seguíamos seguiamos seguían seguian seguí segui siguió siguio siguieron siguiendo seguido".split(
      " "
    ),
  llevar:
    "llevar llevo llevas lleva llevamos lleváis llevais llevan llevaba llevabas llevábamos llevabamos llevabais llevaban llevé lleve llevaste llevó llevo llevaron llevando llevado".split(
      " "
    ),
};

const AUXILIARIES = ["estar", "ir", "andar", "venir", "seguir", "llevar"];

const withBare = (forms) => {
  const set = new Set();
  for (const form of forms) {
    const lower = form.toLowerCase();
    set.add(lower);
    set.add(fold(lower));
  }
  return set;
};

const regularForms = (infinitive) => {
  const ending = infinitive.slice(-2);
  const stem = infinitive.slice(0, -2);
  const forms = [infinitive];
  if (ending === "ar") {
    forms.push(
      `${stem}o`,
      `${stem}as`,
      `${stem}a`,
      `${stem}amos`,
      `${stem}áis`,
      `${stem}an`,
      `${stem}aba`,
      `${stem}abas`,
      `${stem}ábamos`,
      `${stem}abais`,
      `${stem}aban`,
      `${stem}é`,
      `${stem}aste`,
      `${stem}ó`,
      `${stem}asteis`,
      `${stem}aron`,
      `${stem}ado`,
      `${stem}ando`
    );
  } else if (ending === "er" || ending === "ir") {
    const plural = ending === "er" ? `${stem}emos` : `${stem}imos`;
    const you = ending === "er" ? `${stem}éis` : `${stem}ís`;
    forms.push(
      `${stem}o`,
      `${stem}es`,
      `${stem}e`,
      plural,
      you,
      `${stem}en`,
      `${stem}ía`,
      `${stem}ías`,
      `${stem}íamos`,
      `${stem}íais`,
      `${stem}ían`,
      `${stem}í`,
      `${stem}iste`,
      `${stem}ió`,
      `${stem}imos`,
      `${stem}isteis`,
      `${stem}ieron`,
      `${stem}ido`,
      `${stem}iendo`
    );
  }
  return withBare(forms);
};

export const isInfinitiveShape = (word) =>
  /^[\p{L}]{4,}(ar|er|ir)$/iu.test(word);

export const formsOf = (lemma) => {
  const key = lemma.toLowerCase();
  if (IRREGULARS[key]) return withBare(IRREGULARS[key]);
  if (isInfinitiveShape(key) && !NON_INFINITIVES.has(fold(key))) {
    return regularForms(key);
  }
  return new Set([key]);
};

export const shouldConjugate = (word) => {
  const key = word.toLowerCase();
  if (IRREGULARS[key]) return true;
  if (!isInfinitiveShape(key) || NON_INFINITIVES.has(fold(key))) return false;
  if (NOUNS.has(key) && !VERBS.has(key)) return false;
  return true;
};

let cachedAuxiliaries = null;

export const auxiliaryForms = () => {
  if (cachedAuxiliaries) return cachedAuxiliaries;
  const forms = new Set();
  for (const lemma of AUXILIARIES) {
    for (const form of formsOf(lemma)) forms.add(form);
  }
  cachedAuxiliaries = forms;
  return forms;
};

const gerundCache = new Map();

const isGerundWord = (word) => {
  if (gerundCache.has(word)) return gerundCache.get(word);
  const found = findGerunds(word, new Set());
  const yes =
    found.length === 1 &&
    found[0].start === 0 &&
    found[0].end === word.length &&
    !found[0].excluded;
  gerundCache.set(word, yes);
  return yes;
};

const isParticiple = (word) =>
  /^[\p{L}]{3,}(?:ado|ada|ados|adas|ido|ida|idos|idas)$/iu.test(word);

const categoryCache = new Map();

export const categoriesFor = (surface) => {
  const word = surface.toLowerCase();
  const cached = categoryCache.get(word);
  if (cached) return cached;
  const folded = fold(word);
  const tags = new Set();
  const article = ARTICLES.has(word);
  const preposition = PREPOSITIONS.has(word) || PREPOSITIONS.has(folded);
  const pronoun = PRONOUNS.has(word) || PRONOUNS.has(folded);
  const conjunction = CONJUNCTIONS.has(word) || CONJUNCTIONS.has(folded);
  if (article) tags.add("articulo");
  if (preposition) tags.add("preposicion");
  if (pronoun) tags.add("pronombre");
  if (conjunction) tags.add("conjuncion");
  const closed = article || preposition || pronoun || conjunction;

  if ((ADVERBS.has(word) || (word.endsWith("mente") && word.length > 5)) && !closed) {
    tags.add("adverbio");
  }
  if (NOUNS.has(word) && !closed) tags.add("sustantivo");
  if (ADJECTIVES.has(word) && !closed) tags.add("adjetivo");
  if (VERBS.has(word) && !closed) tags.add("verbo");
  if (isGerundWord(word)) {
    tags.add("gerundio");
    tags.add("verbo");
  }
  if (isParticiple(word) && !closed) {
    tags.add("participio");
    tags.add("verbo");
  }
  if (isInfinitiveShape(word) && !NON_INFINITIVES.has(folded) && !closed) {
    tags.add("infinitivo");
    tags.add("verbo");
  }
  categoryCache.set(word, tags);
  return tags;
};

export const LEXICAL = new Set([
  "sustantivo",
  "adjetivo",
  "adverbio",
  "verbo",
  "gerundio",
  "infinitivo",
  "participio",
]);
