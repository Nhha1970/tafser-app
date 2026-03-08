
const fs = require('fs');

const data = JSON.parse(fs.readFileSync('araaf_merged.json', 'utf8'));
const basmalah = "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ ";

let output = "const List<Map<String, String>> araafData = [\n";

data.forEach((item) => {
    let v = item.v;
    if (item.n === "1" && v.startsWith(basmalah)) {
        v = v.substring(basmalah.length);
    }

    // Escape single quotes and backslashes
    const escapedV = v.replace(/'/g, "\\'");
    const escapedT = item.t.replace(/'/g, "\\'");

    output += `  {'s': '${item.s}', 'n': '${item.n}', 'v': '${escapedV}', 't': '${escapedT}'},\n`;
});

output += "];\n";

fs.writeFileSync('araaf_dart.txt', output, 'utf8');
console.log('Done! Saved to araaf_dart.txt');
