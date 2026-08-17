#!/usr/bin/env node
// Usage: node measure-quality.js <path-to-java-file> <method-name>
// Mechanical, judgment-free proxies for Step 7 readability: max brace-nesting
// depth inside the method body, and a count of "magic" numeric/string
// literals (the fixture's chkShipElig uses 30, 20, 5 and "IT"/"FR"/"DE" as
// bare literals — a Step 7 pass should replace these with named constants).
const fs = require('fs');

const [, , filePath, methodName] = process.argv;
if (!filePath || !methodName) {
  console.log('USAGE_ERROR');
  process.exit(1);
}
if (!fs.existsSync(filePath)) {
  console.log('FILE_NOT_FOUND');
  process.exit(0);
}

const lines = fs.readFileSync(filePath, 'utf8').split('\n');
let startLine = -1;
for (let i = 0; i < lines.length; i++) {
  const l = lines[i];
  if (l.includes(methodName + '(') && /public|private|protected/.test(l) && !l.trim().startsWith('//')) {
    startLine = i;
    break;
  }
}
if (startLine === -1) {
  console.log('METHOD_NOT_FOUND');
  process.exit(0);
}

let depth = 0;
let maxDepth = 0;
let started = false;
const bodyLines = [];
for (let i = startLine; i < lines.length; i++) {
  const line = lines[i];
  bodyLines.push(line);
  for (const ch of line) {
    if (ch === '{') {
      depth++;
      started = true;
      if (depth > maxDepth) maxDepth = depth;
    } else if (ch === '}') {
      depth--;
    }
  }
  if (started && depth === 0) break;
}
const body = bodyLines.join('\n');

const numberMatches = body.match(/(?<![\w.])\d+(\.\d+)?(?!\w)/g) || [];
const stringMatches = body.match(/"(IT|FR|DE|US)"/g) || [];

console.log('MAX_NESTING_DEPTH=' + Math.max(0, maxDepth - 1)); // -1: the method's own opening brace is depth 1
console.log('MAGIC_NUMBER_COUNT=' + numberMatches.length);
console.log('MAGIC_STRING_COUNT=' + stringMatches.length);
console.log('METHOD_LINES=' + bodyLines.length);
