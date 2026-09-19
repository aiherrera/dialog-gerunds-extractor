import fs from "fs";
import path from "path";
import mammoth from "mammoth";
import { Document, Packer, Paragraph, TextRun } from "docx";
import { findGerunds } from "../gerunds.js";
import { loadExclusionList } from "../exclusion-list.js";
import { transformFilename } from "../transform-filename.js";
import { paragraphsFromText } from "../paragraphs.js";

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

const runsForParagraph = (paragraphText, exclusionList, speaker) => {
  const runs = [];
  const records = [];
  let cursor = 0;
  let highlighted = 0;
  let excluded = 0;

  for (const gerund of findGerunds(paragraphText, exclusionList)) {
    if (gerund.start > cursor) {
      runs.push(new TextRun(paragraphText.slice(cursor, gerund.start)));
    }

    const text = paragraphText.slice(gerund.start, gerund.end);
    const context = contextAround(paragraphText, gerund.start, gerund.end);
    records.push({
      word: gerund.word.toLowerCase(),
      excluded: gerund.excluded,
      speaker,
      ending: gerund.ending,
      clitic: gerund.clitic.toLowerCase(),
      crossesTag: gerund.crossesTag,
      before: context.before,
      match: context.match,
      after: context.after,
    });

    if (gerund.excluded) {
      excluded += 1;
      runs.push(new TextRun(text));
    } else {
      highlighted += 1;
      runs.push(
        new TextRun({
          text,
          color: "FF0000",
        })
      );
    }

    cursor = gerund.end;
  }

  if (cursor < paragraphText.length) {
    runs.push(new TextRun(paragraphText.slice(cursor)));
  }

  if (runs.length === 0) {
    runs.push(new TextRun(""));
  }

  return { runs, highlighted, excluded, records };
};

export const highlightGerundsInDocx = async (
  inputFilePath,
  outputDirectory,
  exclusionListPath,
  metadata = {}
) => {
  const exclusionList = loadExclusionList(exclusionListPath);
  const result = await mammoth.extractRawText({ path: inputFilePath });
  const paragraphs = paragraphsFromText(result.value);

  let highlighted = 0;
  let excluded = 0;
  const gerunds = [];

  const doc = new Document({
    creator: metadata.creator,
    title: metadata.title,
    description: metadata.description,
    sections: [
      {
        properties: {},
        children: paragraphs.map((paragraph, index) => {
          const paragraphRuns = runsForParagraph(
            paragraph.text,
            exclusionList,
            paragraph.speaker
          );
          highlighted += paragraphRuns.highlighted;
          excluded += paragraphRuns.excluded;
          gerunds.push(
            ...paragraphRuns.records.map((record) => ({
              ...record,
              paragraph: index,
            }))
          );

          if (index < paragraphs.length - 1) {
            paragraphRuns.runs.push(new TextRun({ break: 1 }));
          }

          return new Paragraph({ children: paragraphRuns.runs });
        }),
      },
    ],
  });

  const fileName = path.basename(inputFilePath, path.extname(inputFilePath));
  const outputFilePath = path.join(
    outputDirectory,
    `${transformFilename(fileName)}.docx`
  );

  const buffer = await Packer.toBuffer(doc);
  fs.writeFileSync(outputFilePath, buffer);

  return { highlighted, excluded, gerunds, outputFilePath, paragraphs };
};
