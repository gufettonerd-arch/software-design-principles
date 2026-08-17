#!/usr/bin/env node
// software-design-principles — Claude Code SessionStart hook
//
// Runs once per session. If the working directory looks like a real code
// project — a git repo, or a common build/package manifest, checked at the
// root and up to two levels of subdirectories (skipping node_modules,
// .git internals, build output, etc.) — prints the skill's working
// checklist to stdout so it's part of the session's context from the
// start. The checklist is read live from SKILL.md, not duplicated here,
// so it never drifts out of sync with the skill itself.
//
// Anything past "does this look like a code project at all" is left to
// Claude's own judgment per task, on purpose: a SessionStart hook runs
// before the first user message even exists, so it has no signal about
// what the task actually is — only the environment does. See the
// "Known limitations" section of the README for the reasoning.

const fs = require('fs');
const path = require('path');

const IGNORE_DIRS = new Set([
  'node_modules', 'dist', 'build', 'target', 'out',
  '.venv', 'venv', '__pycache__', 'vendor', '.next', '.astro', 'coverage',
]);

const MARKER_FILES = [
  'package.json', 'pom.xml', 'build.gradle', 'build.gradle.kts',
  'go.mod', 'Cargo.toml', 'pyproject.toml', 'requirements.txt',
  'composer.json', 'Gemfile',
];

const MAX_DEPTH = 2;

function hasMarkerAt(dir) {
  if (fs.existsSync(path.join(dir, '.git'))) return true;
  return MARKER_FILES.some((f) => fs.existsSync(path.join(dir, f)));
}

function looksLikeCodeProject(root, depth = 0) {
  if (hasMarkerAt(root)) return true;
  if (depth >= MAX_DEPTH) return false;

  let entries;
  try {
    entries = fs.readdirSync(root, { withFileTypes: true });
  } catch (e) {
    return false; // unreadable dir — not our problem, just skip
  }

  return entries.some((entry) => {
    if (!entry.isDirectory()) return false;
    if (entry.name.startsWith('.')) return false; // .git handled by hasMarkerAt; skip other dotdirs
    if (IGNORE_DIRS.has(entry.name)) return false;
    return looksLikeCodeProject(path.join(root, entry.name), depth + 1);
  });
}

function extractWorkingChecklist(skillPath) {
  const text = fs.readFileSync(skillPath, 'utf8');
  const sections = text.split(/\n(?=## )/);
  const checklist = sections.find((s) => s.startsWith('## Working checklist'));
  return checklist ? checklist.trim() : null;
}

try {
  const projectDir = process.env.CLAUDE_PROJECT_DIR || process.cwd();

  if (!looksLikeCodeProject(projectDir)) {
    process.exit(0); // doesn't look like a code project — stay silent
  }

  const skillPath = path.join(__dirname, '..', 'skills', 'software-design-principles', 'SKILL.md');
  const checklist = extractWorkingChecklist(skillPath);
  if (!checklist) process.exit(0); // SKILL.md reshaped — fail silent, never block the session

  process.stdout.write(
    "This looks like a code project. The software-design-principles skill is installed — " +
    "here's its working checklist. Apply it when it's actually relevant to what the user asks " +
    "(writing, reviewing, or refactoring code) — for the full 20 principles or the god-class " +
    "extraction playbook, consult the software-design-principles skill directly.\n\n" +
    checklist
  );
} catch (e) {
  // Never block session start over this hook.
  process.exit(0);
}
