
const fs = require('fs');
const data = JSON.parse(fs.readFileSync('anam_merged.json', 'utf8'));

let output = 'const List<Map<String, String>> anamData = [\n';

data.forEach(item => {
    // Escape single quotes in strings
    const v = item.v.replace(/'/g, "\\'");
    const t = item.t.replace(/'/g, "\\'");
    const s = item.s;
    const n = item.n;

    output += `  {'s': '${s}', 'n': '${n}', 'v': '${v}', 't': '${t}'},\n`;
});

output += '];\n';

fs.writeFileSync('anam_dart.txt', output, 'utf8');
console.log('Done! Formatted data saved to anam_dart.txt');
