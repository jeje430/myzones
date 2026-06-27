import fs from "fs";
import path from "path";

const root = path.resolve("src/features");

function walk(dir, out = []) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, entry.name);
    if (entry.isDirectory()) walk(p, out);
    else if (entry.name.endsWith(".jsx")) out.push(p);
  }
  return out;
}

let fixed = 0;

for (const file of walk(root)) {
  let source = fs.readFileSync(file, "utf8");
  if (/return \(\s*\n\s*<>/.test(source)) continue;

  const needs =
    /return \(\s*\n\s*<PageHeader[^>]*\/>\s*\n\s*\n\s*\{/.test(source) ||
    /return \(\s*\n\s*<PageHeader[^>]*\/>\s*\n\s*\n\s*<section/.test(source) ||
    /return \(\s*\n\s*<PageHeader[^>]*\/>\s*\n\s*\n\s*<div/.test(source) ||
    /\n      <\/div>\n\n      <[A-Z]/.test(source);

  if (!needs) continue;

  source = source.replace(/return \(\s*\n(\s*)/, "return (\n$1<>\n$1");
  const idx = source.lastIndexOf("\n  );");
  if (idx === -1) continue;
  source = `${source.slice(0, idx)}\n    </>${source.slice(idx)}`;
  fs.writeFileSync(file, source);
  fixed += 1;
  console.log(path.relative(root, file));
}

console.log("fixed", fixed);
