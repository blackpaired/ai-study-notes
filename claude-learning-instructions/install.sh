#!/usr/bin/env bash
# Installs the study-notes skill and the proofreading agent for Claude Code.
# Usage: open a terminal in this folder and run  bash install.sh
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"

mkdir -p ~/.claude/skills ~/.claude/agents
rm -rf ~/.claude/skills/study-notes
cp -r "$here/skills/study-notes" ~/.claude/skills/
cp "$here/agents/study-notes-checker.md" ~/.claude/agents/
chmod +x ~/.claude/skills/study-notes/build_pdf.sh

echo "✔ Skill installed:  ~/.claude/skills/study-notes/"
echo "✔ Agent installed:  ~/.claude/agents/study-notes-checker.md"
echo
echo "Required programs:"
missing=0
check() { if command -v "$1" >/dev/null 2>&1; then echo "  ✔ $1"; else echo "  ✘ $1 missing  ($2)"; missing=1; fi; }
check claude      "Claude Code: https://claude.com/claude-code"
check markitdown  "pip install 'markitdown[all]'  or  pipx install 'markitdown[all]'"
check pandoc      "package manager, e.g. sudo pacman -S pandoc / sudo apt install pandoc / brew install pandoc"
check pdftoppm    "poppler: sudo pacman -S poppler / sudo apt install poppler-utils / brew install poppler"
check tesseract   "optional, for scans: tesseract + language packs"
browser=no
for b in chromium chromium-browser google-chrome-stable google-chrome brave brave-browser microsoft-edge; do
  command -v "$b" >/dev/null 2>&1 && browser=yes
done
for app in "Google Chrome" "Chromium" "Brave Browser"; do
  [ -d "/Applications/$app.app" ] && browser=yes
done
if [ "$browser" = yes ]; then echo "  ✔ Chromium/Chrome/Brave"; else echo "  ✘ Chromium/Chrome/Brave missing (needed for the PDF)"; missing=1; fi

echo
[ "$missing" = 0 ] && echo "All set!" || echo "Please install the missing programs (see above)."
echo "Then (re)start Claude Code and type  /study-notes <folder>"
