# Dialog Gerunds Extractor

This Node.js application extracts and highlights gerunds from a corpus of `.doc`, `.rtf`, and `.docx` files, while providing the option to exclude specific words.

## Features

- **Converts documents to .docx:** Uses macOS `textutil` to convert legacy `.doc` and `.rtf` files to `.docx`. The converted text matches the original.
- **Identifies and highlights gerunds:** Finds `-ando`, `-iendo`, and `-yendo`, including accented forms with pronouns (`dándole`) and words split by a transcription tag (`conversa<alargamiento/>ndo`).
- **Exclusion list:** Allows you to specify words to be excluded from highlighting, even if they match the gerund pattern.

## Requirements

- **Node.js:** Version 20 or higher ([https://nodejs.org/](https://nodejs.org/))
- **macOS:** `textutil` comes with the system and converts `.doc` and `.rtf`. No LibreOffice install is required.

## Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/dialog-gerunds-extractor.git
   cd dialog-gerunds-extractor
   ```
2. **Install dependencies:**
   ```bash
    pnpm install
   ```
3. **Run the application:**
   ```bash
   pnpm start
   ```

## Usage

1. **Corpus Directory:**

   - Place all your `.doc`, `.rtf`, and `.docx` files in the `corpus` directory.
   - Example:
     ```
     corpus/
        document1.doc
        document2.rtf
        document3.docx
     ```

2. **Exclusion List (Optional):**

   - Edit `utils/exclusion_list.txt`.
   - List one excluded word per line in the file.
   - Example (`exclusion_list.txt`):
     ```
     running
     walking
     swimming
     ```

3. **Run the Application:**

   - Open your terminal or command prompt.
   - Navigate to the project directory.
   - Run the following command:

     ```bash
     pnpm start
     ```

## Output

The processed files with highlighted gerunds will be saved in the following directories:

- **`output/converted_to_docx`:** Converted `.docx` versions of the input files (if applicable).
- **`output/highlighted`:** Final `.docx` files with highlighted gerunds.
- **`output/stats.txt`:** Totals by speaker, sex, interview group, ending, and pronoun.
- **`output/gerunds-by-type.tsv`:** Every highlighted gerund and how often it occurs.
- **`output/gerunds-by-file.tsv`:** Counts per interview, including informant and interviewer.
- **`output/concordance.json`:** Examples for the Mac app.

## Mac app

Andante is the screenshot window. **Elegir corpus** opens the `corpus` folder and processes it; when it finishes, the summary is on screen. Concordance, frequencies, and the summary use the same filters.

```bash
pnpm app
```

The app is `macos/Andante.app`.

## Contributing

Contributions are welcome! If you have any improvements or bug fixes, please follow these steps:

1. **Fork the repository** on GitHub.

2. **Create a new branch** for your feature or bug fix.

3. **Make your changes** and commit them with clear messages.

4. **Push your changes** to your forked repository.

5. **Submit a pull request** to the main repository.

## License

This project is licensed under the [MIT License](LICENSE).

## Acknowledgments

- [Mammoth.js](https://www.npmjs.com/package/mammoth): For converting .docx files to text.
- [docx](https://www.npmjs.com/package/docx): For creating and manipulating .docx files.
- [textutil](https://ss64.com/mac/textutil.html): For converting `.doc` and `.rtf` files to `.docx` on macOS.
