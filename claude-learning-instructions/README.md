# Claude Learning Instructions

A [Claude Code](https://claude.com/claude-code) skill that turns your study materials (PDFs, lecture notes, slides, even scans) into study notes that explain **why** things are the way they are. You don't just get a list of facts. A separate proofreading agent checks every fact against your sources, and the result is exported as a nicely formatted PDF.

## What you get

- **Core rules first:** 3–5 principles from which the rest can be derived.
- **🔎 Why boxes** that explain the connections behind the facts.
- **💡 Mnemonics** (only ones that are factually correct).
- **Fact tables** taken from your materials, plus a final overview/comparison table.
- **Proofreading agent** (`study-notes-checker`) that compares every line with the original sources and reports errors, missing content and doubtful explanations.
- **PDF output** with a cover page, table of contents and colour-coded chapters.

## How it works

1. **Read:** PDFs are converted to text with `markitdown`. For scanned pages, Claude looks at rendered page images directly, so tables don't get scrambled by OCR.
2. **Ask:** Claude asks you 4 quick questions: structure, content, scope and style.
3. **Write:** It creates `<Topic>_Connections.md` in your materials folder.
4. **Check:** The proofreading agent checks everything, and justified corrections are applied.
5. **Export:** `<Topic>_Connections.pdf` is created next to the notes.

## Requirements

- [Claude Code](https://claude.com/claude-code)
- Linux or macOS (Windows via WSL)
- [`markitdown`](https://github.com/microsoft/markitdown): `pipx install 'markitdown[all]'`
- [`pandoc`](https://pandoc.org): `sudo pacman -S pandoc` / `sudo apt install pandoc` / `brew install pandoc`
- `poppler`: `sudo pacman -S poppler` / `sudo apt install poppler-utils` / `brew install poppler`
- Chromium, Google Chrome or Brave (used to render the PDF)
- Optional, for scanned PDFs: `tesseract` plus the language packs you need

## Installation

```bash
git clone https://github.com/<your-username>/claude-learning-instructions.git
cd claude-learning-instructions
bash install.sh
```

The script copies the skill to `~/.claude/skills/study-notes/` and the agent to `~/.claude/agents/`. It also shows which required programs are missing.

To install by hand instead:

```bash
mkdir -p ~/.claude/skills ~/.claude/agents
cp -r skills/study-notes ~/.claude/skills/
cp agents/study-notes-checker.md ~/.claude/agents/
```

Then restart Claude Code.

## Usage

Put all materials for one exam into one folder, then in Claude Code type:

```
/study-notes ~/Documents/Physiology/
```

Plain language works too: *"make me study notes from ~/Documents/Physiology"*.

The notes are written in the language of your materials. Some useful follow-ups:

- "add 20 self-test questions with answers at the end"
- "make the PDF more compact, don't start every chapter on a new page"
- "explain section 7 again in simpler terms"
- "quiz me"

### Proofreading only

```
@study-notes-checker check ~/Documents/Physiology/Heart_Connections.md against the materials in the same folder
```

### Rebuilding the PDF only

If you edited the `.md` yourself, run:

```bash
~/.claude/skills/study-notes/build_pdf.sh ~/Documents/Physiology/Heart_Connections.md
```

## Writing format

| Markdown | Result |
|---|---|
| `## 3. Heading {.green}` | New chapter on a new page, in green (`gray blue green orange purple red teal pink`). Without `{.colour}` it inherits the previous colour. |
| `### Subheading` | Subsection |
| `**Why?** text …` | Teal 🔎 box. A directly following list or table is included. |
| `**Mnemonic:** text …` | Orange 💡 box. A directly following list or table is included. |
| `> text` | Blue info box |

The box keywords (`Why`, `Mnemonic`, `Remember`) must be in English, even when the notes are in another language.

The YAML header at the top controls the cover page:

```yaml
---
title: "Heart<br>Understanding the connections"
kicker: "Physiology · Module 2"
subtitle: "How the heart works – with the <b>why</b>."
legend:
  - name: "Core rules"
    color: gray
  - name: "Heart"
    color: red
---
```

To change the design (colours, fonts), edit `~/.claude/skills/study-notes/template.html`.

## Important

- Facts come from your materials. "Why" explanations and mnemonics partly come from general knowledge. **If anything contradicts your lecture or textbook, your lecture wins.**
- The proofreading agent catches a lot, but it is not guaranteed to catch everything.
- Every run uses your Claude usage, and many PDF pages mean more usage.
