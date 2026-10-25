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
dest="$skills/study-notes"
keep="$(mktemp -d)"
trap 'rm -rf "$keep"' EXIT

# Is this one of the templates we shipped (so the user did not change it)?
# 355348631 6203 = cksum of the template before .template.orig existed
is_stock() {
  cmp -s "$1" "$here/skills/study-notes/template.html" && return 0
  [ -f "$dest/.template.orig" ] && cmp -s "$1" "$dest/.template.orig" && return 0
  [ "$(cksum < "$1" | awk '{print $1, $2}')" = "355348631 6203" ]
}

# Never lose the user's own files: my-template.html, earlier backups and a hand-edited template.html
saved=""
if [ -d "$dest" ]; then
  for f in "$dest"/my-template.html "$dest"/template.html.backup*; do
    if [ -f "$f" ]; then cp "$f" "$keep/"; fi
  done
  if [ -f "$dest/template.html" ] && ! is_stock "$dest/template.html"; then
    saved="template.html.backup-$(date +%Y%m%d-%H%M%S)"
    cp "$dest/template.html" "$keep/$saved"
  fi
fi
rm -rf "$dest"
cp -r "$here/skills/study-notes" "$skills/"
cp "$here/skills/study-notes/template.html" "$dest/.template.orig"
for f in "$keep"/*; do
  if [ -f "$f" ]; then cp "$f" "$dest/"; fi
done
# The skill also needs the checker instructions in its own folder (for tools without subagents)
cp "$here/agents/study-notes-checker.md" "$skills/study-notes/"
cp "$here/agents/study-notes-checker.md" "$agents/"
chmod +x "$skills/study-notes/build_pdf.sh"

echo "Skill installed:  $skills/study-notes/"
echo "Agent installed:  $agents/study-notes-checker.md"
if [ -n "$saved" ]; then
  echo "! You had changed template.html. Your version was saved as  $dest/$saved"
  echo "  To keep using it, rename it to my-template.html (build_pdf.sh uses that file automatically"
  echo "  and future installs keep it):  mv \"$dest/$saved\" \"$dest/my-template.html\""
fi
echo
echo "Required programs:"
missing=0
check() { if command -v "$1" >/dev/null 2>&1; then echo "  ok       $1"; else echo "  MISSING  $1  ($2)"; missing=1; fi; }
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
if [ "$browser" = yes ]; then echo "  ok       Chromium/Chrome/Brave"; else echo "  MISSING  Chromium/Chrome/Brave (needed for the PDF)"; missing=1; fi

echo
[ "$missing" = 0 ] && echo "All set!" || echo "Please install the missing programs (see above)."
echo "Then (re)start your AI agent and type  /study-notes <folder>"
echo "(or just ask: \"make me study notes from <folder>\")"
