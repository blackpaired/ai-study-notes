#!/usr/bin/env bash
# Installs the study-notes skill and the proofreading agent for your terminal AI agent.
# Usage: open a terminal in this folder and run
#   bash install.sh [skills-folder] [agents-folder]
# Defaults: ~/.claude/skills and ~/.claude/agents (used by Claude Code and read by some other tools).
# Pass the folders your AI tool loads skills/agents from to install somewhere else.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
skills="${1:-$HOME/.claude/skills}"
agents="${2:-$(dirname "$skills")/agents}"

mkdir -p "$skills" "$agents"
rm -rf "$skills/study-notes"
cp -r "$here/skills/study-notes" "$skills/"
# The skill also needs the checker instructions in its own folder (for tools without subagents)
cp "$here/agents/study-notes-checker.md" "$skills/study-notes/"
cp "$here/agents/study-notes-checker.md" "$agents/"
chmod +x "$skills/study-notes/build_pdf.sh"

echo "✔ Skill installed:  $skills/study-notes/"
echo "✔ Agent installed:  $agents/study-notes-checker.md"
echo
echo "Required programs:"
missing=0
check() { if command -v "$1" >/dev/null 2>&1; then echo "  ✔ $1"; else echo "  ✘ $1 missing  ($2)"; missing=1; fi; }
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
echo "Then (re)start your AI agent and type  /study-notes <folder>"
echo "(or just ask: \"make me study notes from <folder>\")"
