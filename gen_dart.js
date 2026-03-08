
const fs = require('fs');

const raw = fs.readFileSync('maidah_merged.json', 'utf8');
const data = JSON.parse(raw);

let dart = 'const List<Map<String, String>> maidahData = [\n';

for (const item of data) {
    const s = 'المائدة';
    const n = item.n;
    const v = item.v;
    const t = item.t.replace(/'/g, "\\'");

    dart += `  {'s': '${s}', 'n': '${n}', 'v': '${v}', 't': '${t}'},\n`;
}

dart += '];\n';

fs.writeFileSync('maidah_dart.txt', dart, 'utf8');
console.log('Done! Generated maidah_dart.txt');
