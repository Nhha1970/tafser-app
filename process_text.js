
// This is a temporary processing script to clean and split the user's provided text
// for easier import into the Tafser app's bulk entry.

const rawContent = `[PASTE_USER_TEXT_HERE]`;

function processContent(text) {
    // Regex to match Quranic verses (inside ﴿ ﴾ symbols)
    const quranRegex = /﴿([^﴾]+)﴾/g;
    // Regex to match Tafsir lines starting with a number like "٦-"
    const tafsirRegex = /(\d+)- ([^]+?)(?=\n\d+-|$)/g;

    let verses = [];
    let match;
    while ((match = quranRegex.exec(text)) !== null) {
        let verseText = match[1].trim();
        // Remove the verse numbers (digits at the end of parts of the verse) if necessary, 
        // but the app adds them automatically.
        verses.push(verseText);
    }

    let tafsirs = [];
    while ((match = tafsirRegex.exec(text)) !== null) {
        tafsirs.push(match[2].trim());
    }

    console.log("--- VERSES (BULK ENTRY) ---");
    console.log(verses.join('\n'));
    console.log("\n--- TAFSIRS (BULK ENTRY) ---");
    console.log(tafsirs.join('\n'));
}

// Note: I will perform the splitting manually based on the user's structure
// because the text is already very well structured.
