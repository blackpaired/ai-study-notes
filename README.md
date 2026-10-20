# AI Study Notes

A skill for **terminal AI agents** (AI coding agents / agentic CLIs such as Claude Code, Codex CLI, Gemini CLI, OpenCode …) that turns your study materials (PDFs, lecture notes, slides, even scans) into study notes that explain **why** things are the way they are. You don't just get a list of facts. A separate proofreading agent checks every fact against your sources, and the result is exported as a nicely formatted PDF.

## What you get

- **Core rules first:** 3–5 principles from which the rest can be derived.
- **Why boxes** that explain the connections behind the facts.
- **Mnemonics** (only ones that are factually correct).
- **Fact tables** taken from your materials, plus a final overview/comparison table.
- **Proofreading agent** (`study-notes-checker`) that compares every line with the original sources and reports errors, missing content and doubtful explanations.
- **PDF output** with a cover page, table of contents and colour-coded chapters.

## How it works

1. **Read:** PDFs are converted to text with `markitdown`. For scanned pages, the AI looks at rendered page images directly, so tables don't get scrambled by OCR.
2. **Ask:** The AI asks you 4 quick questions: structure, content, scope and style.
3. **Write:** It creates `<Topic>_Connections.md` in your materials folder.
4. **Check:** The proofreading agent checks everything, and justified corrections are applied.
5. **Export:** `<Topic>_Connections.pdf` is created next to the notes.

## Requirements

- A terminal AI agent that can read files and run shell commands. Skill and subagent support is a plus, but not required.
- Linux or macOS (Windows via WSL)
- [`markitdown`](https://github.com/microsoft/markitdown): `pipx install 'markitdown[all]'`
- [`pandoc`](https://pandoc.org): `sudo pacman -S pandoc` / `sudo apt install pandoc` / `brew install pandoc`
- `poppler`: `sudo pacman -S poppler` / `sudo apt install poppler-utils` / `brew install poppler`
- Chromium, Google Chrome or Brave (used to render the PDF)
- Optional, for scanned PDFs: `tesseract` plus the language packs you need

## Installation

```bash
git clone https://github.com/blackpaired/ai-study-notes.git
cd ai-study-notes
bash install.sh
```

By default the script copies the skill to `~/.claude/skills/study-notes/` and the agent to `~/.claude/agents/`. Claude Code and some other tools read skills from there (`SKILL.md` is an open format used by several AI agents). If your AI tool loads skills from a different folder, pass it:

```bash
bash install.sh ~/.my-ai-tool/skills ~/.my-ai-tool/agents
```

The script also shows which required programs are missing.

To install by hand instead:

```bash
mkdir -p <skills-folder> <agents-folder>
cp -r skills/study-notes <skills-folder>/
cp agents/study-notes-checker.md <skills-folder>/study-notes/
cp agents/study-notes-checker.md <agents-folder>/
chmod +x <skills-folder>/study-notes/build_pdf.sh
```

Then restart your AI agent.

**Tool without skill support?** It still works: tell the AI *"follow the instructions in `<skills-folder>/study-notes/SKILL.md` for ~/Documents/Physiology/"*.

## Usage

Put all materials for one exam into one folder, then in your AI agent type:

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

Without subagent support: *"proofread Heart_Connections.md following study-notes-checker.md"*.

### Rebuilding the PDF only

If you edited the `.md` yourself, run:

```bash
<skills-folder>/study-notes/build_pdf.sh ~/Documents/Physiology/Heart_Connections.md
```

## Writing format

| Markdown | Result |
|---|---|
| `## 3. Heading {.green}` | New chapter on a new page, in green (`gray blue green orange purple red teal pink`). Without `{.colour}` it inherits the previous colour. |
| `### Subheading` | Subsection |
| `**Why?** text …` | Teal box. A directly following list or table is included. |
| `**Mnemonic:** text …` | Orange box. A directly following list or table is included. |
| `> text` | Blue info box |

The box keywords (`Why`, `Mnemonic`, `Remember`) must be in English, even when the notes are in another language.

The YAML header at the top controls the cover page:

```yaml
---
title: "Heart<br>Understanding the connections"
kicker: "Physiology · Module 2"
lang: en                 # language of the notes, e.g. de
toc-title: "Contents"    # heading of the table of contents, e.g. "Inhalt"
why-label: "Why box"     # cover legend labels, e.g. "Warum-Box"
mnemonic-label: "Mnemonic"   # e.g. "Eselsbrücke"
subtitle: "How the heart works – with the <b>why</b>."
legend:
  - name: "Core rules"
    color: gray
  - name: "Heart"
    color: red
---
```

All fields except `title` are optional.

To change the design (colours, fonts), copy `<skills-folder>/study-notes/template.html` to `my-template.html` in the same folder and edit the copy. `build_pdf.sh` uses it automatically, and `install.sh` keeps it when you update.

## Important

- Facts come from your materials. "Why" explanations and mnemonics partly come from general knowledge. **If anything contradicts your lecture or textbook, your lecture wins.**
- The proofreading agent catches a lot, but it is not guaranteed to catch everything.
- Every run uses your AI usage (tokens / plan limits), and many PDF pages mean more usage.

---

*This repo was created with the help of Claude Opus 5.5*
