#!/usr/bin/env bash
# Builds a formatted PDF from a study-notes Markdown file.
# Usage: build_pdf.sh <input.md> [output.pdf]
set -euo pipefail

in="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
out="${2:-${in%.md}.pdf}"
case "$out" in /*) ;; *) out="$PWD/$out" ;; esac
here="$(cd "$(dirname "$0")" && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

meta=()
if head -1 "$in" | grep -q '^---$'; then
  cp "$in" "$work/raw.md"
else
  # No YAML header: the first "# Heading" becomes the title
  title="$(grep -m1 '^# ' "$in" | sed 's/^# //' || true)"
  meta=(-M "title=${title:-Study notes}")
  awk 'done || !/^# / { print; next } { done=1 }' "$in" > "$work/raw.md"
fi

# Force a blank line before tables and lists (otherwise pandoc glues them to the previous paragraph),
# but not inside the YAML header or ``` code blocks
awk 'NR==1 && /^---$/ { yaml=1; print; prev=$0; next }
     yaml { print; if (/^(---|\.\.\.)$/) yaml=0; prev=$0; next }
     /^```/ { code=!code; print; prev=$0; next }
     code { print; prev=$0; next }
     { if ((/^\|/ && prev !~ /^\|/ && prev != "") || (/^- / && prev !~ /^(- |  )/ && prev != "" && prev != "---")) print ""; print; prev=$0 }' \
  "$work/raw.md" > "$work/in.md"

pandoc "$work/in.md" -f markdown -t html5 --template "$here/template.html" \
  --toc --toc-depth=3 ${meta[@]+"${meta[@]}"} -o "$work/out.html"

# Find a Chromium-based browser (Linux and macOS)
browser=""
for b in chromium chromium-browser google-chrome-stable google-chrome brave brave-browser microsoft-edge \
         "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
         "/Applications/Chromium.app/Contents/MacOS/Chromium" \
         "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"; do
  if command -v "$b" >/dev/null 2>&1 || [ -x "$b" ]; then browser="$b"; break; fi
done
if [ -z "$browser" ]; then
  echo "No Chromium/Chrome/Brave found – please install one of them." >&2
  exit 1
fi

"$browser" --headless=new --disable-gpu --no-pdf-header-footer --virtual-time-budget=5000 \
  --print-to-pdf="$out" "file://$work/out.html" >/dev/null 2>&1

if command -v pdfinfo >/dev/null 2>&1; then
  echo "PDF created: $out ($(pdfinfo "$out" | awk '/^Pages/ {print $2}') pages)"
else
  echo "PDF created: $out"
fi
