const createReport = require('docx-templates').default;
const textract = require('textract');
const mammoth = require("mammoth");
const { exec } = require('child_process');
const fs = require("fs");
const path = require("path");

// Regular expression for matching gerunds
const gerundRegex = /\b\w*ndo\w*\b/g;

// Load exclusion list from a text file
const loadExclusionList = (filePath) => {
  return new Promise((resolve, reject) => {
    fs.readFile(filePath, { encoding: "utf-8" }, (err, data) => {
      if (err) reject(err);
      else resolve(new Set(data.split("\n")));
    });
  });
};

// Process a single Word document and return matches
const processDocument = async (filePath, exclusionList) => {
  try {
    // Note: Here you would adjust the logic to handle .doc files if necessary
    const result = await mammoth.extractRawText({ path: filePath });
    const matches = result.value.match(gerundRegex) || [];
    const filteredMatches = matches.filter((word) => !exclusionList.has(word.toLowerCase()));
    return filteredMatches;
  } catch (error) {
    console.error(`Error processing ${filePath}:`, error);
    return [];
  }
};

// Read all .doc and .docx files from a directory
const readDocumentsFromDirectory = (directoryPath) => {
  return new Promise((resolve, reject) => {
    fs.readdir(directoryPath, (err, files) => {
      if (err) {
        reject(err);
      } else {
        const documentFiles = files.filter(file => file.endsWith('.docx')).map(file => path.join(directoryPath, file));
        resolve(documentFiles);
      }
    });
  });
};

// Export results to a file
const exportResultsToFile = (uniqueMatches, outputPath) => {
  return new Promise((resolve, reject) => {
    const data = uniqueMatches.join("\n");
    fs.writeFile(outputPath, data, (err) => {
      if (err) reject(err);
      else resolve();
    });
  });
};

// Main function to process documents from a directory, remove duplicate gerunds, and export to a file
const processDocumentsFromDirectory = async (directoryPath, exclusionListPath, outputPath) => {
  const exclusionList = await loadExclusionList(exclusionListPath);
  const docPaths = await readDocumentsFromDirectory(directoryPath);
  let allMatches = [];

  for (const docPath of docPaths) {
    const matches = await processDocument(docPath, exclusionList);
    allMatches = allMatches.concat(matches);
  }

  // Remove duplicates
  const uniqueMatches = [...new Set(allMatches.map(match => match.toLowerCase()))];
  
  // Export unique gerunds to a file
  await exportResultsToFile(uniqueMatches, outputPath);
  console.log(`Unique gerunds from all documents have been exported to ${outputPath}`);
};

// Example usage
const directoryPath = "./corpus/converted_docx";
const exclusionListPath = "./exclusion_list.txt";
const outputPath = "output.txt"; // Path for the output file

processDocumentsFromDirectory(directoryPath, exclusionListPath, outputPath)
  .then(() => console.log("Processing completed."))
  .catch((error) => console.error("An error occurred:", error));