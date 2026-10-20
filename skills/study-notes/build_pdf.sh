#!/usr/bin/env bash
# Builds a formatted PDF from a study-notes Markdown file.
# Usage: build_pdf.sh <input.md> [output.pdf]
set -euo pipefail

if [ $# -lt 1 ] || [ ! -f "$1" ]; then
  echo "Usage: build_pdf.sh <input.md> [output.pdf]" >&2
  exit 1
fi
in="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
out="${2:-${in%.md}.pdf}"
case "$out" in /*) ;; *) out="$PWD/$out" ;; esac
here="$(cd "$(dirname "$0")" && pwd)"
# Work folder next to the output, not in /tmp: snap browsers (e.g. Chromium on Ubuntu) cannot see /tmp
work="$(mktemp -d "$(dirname "$out")/study-notes-build.XXXXXX")"
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

# Force a blank line before tables and lists, otherwise pandoc glues them to the previous paragraph,
# but not inside the YAML header or ``` code blocks. Numbered lists only when they start at 1,
# so wrapped text like "... in the\n3. week" stays text.
awk 'NR==1 && /^---$/ { yaml=1; print; prev=$0; next }
     yaml { print; if (/^(---|\.\.\.)$/) yaml=0; prev=$0; next }
     /^```/ { code=!code; print; prev=$0; next }
     code { print; prev=$0; next }
     { item = "^([-*+]|[0-9]+[.)]) "; start = "^([-*+]|1[.)]) "
       if ((/^\|/ && prev !~ /^\|/ && prev != "") || ($0 ~ start && prev !~ item && prev !~ /^  / && prev != "" && prev != "---")) print ""
       print; prev=$0 }' \
  "$work/raw.md" > "$work/in.md"

# Your own design in my-template.html (next to this script) wins over the shipped template
template="$here/template.html"
if [ -f "$here/my-template.html" ]; then template="$here/my-template.html"; fi

pandoc "$work/in.md" -f markdown -t html5 --template "$template" \
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

# The path is part of a file:// URL: escape characters that have a meaning there (e.g. "Woche #3", "Anna's Uni")
url="file://$(printf '%s' "$work/out.html" | sed -e 's/%/%25/g' -e 's/#/%23/g' -e 's/?/%3F/g' -e "s/'/%27/g")"

# Print into the work folder first, so a failed run never leaves an old or broken PDF looking like a new one
if ! "$browser" --headless=new --disable-gpu --no-pdf-header-footer --virtual-time-budget=5000 \
       --print-to-pdf="$work/out.pdf" "$url" >"$work/browser.log" 2>&1 \
   || [ ! -s "$work/out.pdf" ]; then
  echo "PDF could not be created. Browser output ($browser):" >&2
  tail -n 20 "$work/browser.log" >&2
  exit 1
fi
mv -f "$work/out.pdf" "$out"

if command -v pdfinfo >/dev/null 2>&1; then
  echo "PDF created: $out ($(pdfinfo "$out" | awk '/^Pages/ {print $2}') pages)"
else
  echo "PDF created: $out"
fi
