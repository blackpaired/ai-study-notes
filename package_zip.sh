#!/usr/bin/env bash
# Builds dist/study-notes.zip for AI apps that let you upload skills as a ZIP file.
# Some apps allow at most 200 characters in the skill description, so the ZIP gets this short one;
# the full SKILL.md description stays in the repo.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
short="Turns lecture notes into study notes that explain the why: why boxes, mnemonics, tables, checked against your sources, exported as PDF. Use for study notes or summaries."
[ ${#short} -le 200 ] || { echo "Short description is ${#short} characters (max 200)" >&2; exit 1; }
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
cp -r "$here/skills/study-notes" "$work/study-notes"
rm -rf "$work/study-notes/template" "$work/study-notes/__pycache__"
cp "$here/agents/study-notes-checker.md" "$work/study-notes/"
SHORT="$short" python3 -I - "$work/study-notes/SKILL.md" <<'PY'
import os, re, sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s, n = re.subn(r"^description: .*$", lambda m: "description: " + os.environ["SHORT"], s, count=1, flags=re.M)
assert n == 1, "no description line found"
open(p, "w", encoding="utf-8").write(s)
PY
mkdir -p "$here/dist"
rm -f "$here/dist/study-notes.zip"
python3 -I -c 'import shutil, sys; shutil.make_archive(sys.argv[1], "zip", sys.argv[2], sys.argv[3])' "$here/dist/study-notes" "$work" "study-notes"
echo "Built: $here/dist/study-notes.zip"
