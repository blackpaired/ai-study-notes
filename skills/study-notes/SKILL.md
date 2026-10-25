---
name: study-notes
description: Turns study materials (PDFs, lecture notes, tables, slides in a folder) into understanding-focused study notes that explain connections ("X is like this BECAUSE ...") instead of just listing facts, with "Why?" boxes, mnemonics and overview tables. A proofreading agent then checks everything against the sources, and the result is exported as a nicely formatted PDF. Use when the user wants to study for an exam or test, wants materials "summarized", "connections explained", "study notes" or a "cheat sheet", or invokes /study-notes.
---

# Study notes – understand connections instead of memorizing

The user is studying for exams (any subject: medicine, law, sciences, languages …).
Goal: study notes that **explain why things are the way they are**, with mnemonics, exported as a good-looking PDF.
Language: **if the user writes in the same language as the materials, use that language and don't ask.** If they differ (e.g. the user writes German, the materials are English) or the materials are mixed, **ask at the very start** – as the first question, as soon as you have seen the materials and before anything else – which language they want: the user's language or the language of the materials. Use the multiple-choice question tool if available, otherwise one short line in the chat. Then write the notes in that language (and set `lang` accordingly). This language question comes before the questions in step 2. Friendly and easy to follow, but technically precise.

Argument (optional): path to the folder or files containing the materials. If missing, ask for it.

## Workflow

### 1. Read the materials
- List the folder. For every file without a matching `.md`: `markitdown "file.pdf" -o "file.md"`.
- An **empty or nearly empty `.md`** means the PDF contains only images (scan / "print to PDF"). Check with `pdftotext file.pdf - | head`.
  - **Tables and important pages:** render the pages as images (`pdftoppm -r 130 -png file.pdf <temp-folder>/p`, use a temporary folder outside the materials) and **look at them yourself** if you can view images. Tesseract scrambles table columns.
  - Long running text: OCR with `tesseract image.png - -l eng` (add more languages as needed, e.g. `deu+eng`) is fine.
- Never modify or delete the original files.

### 2. Ask the user how the notes should look
Ask one round of up to 4 questions, adapted to the subject. If your environment has a tool for multiple-choice questions, use it; otherwise ask them as a short numbered list in chat. Pattern:
- **Structure:** How to organize it? (e.g. by nerve / by region / both). Mark the option that shows the most connections as "(Recommended)".
- **Content** (several answers allowed): e.g. connections with reasoning, derivations (location → function), clinical relevance/applications, mnemonics.
- **Scope:** everything or only a part.
- **Style:** short / medium with tables (Recommended) / very detailed.
If the user skips the questions or does not answer them, use the recommended options and say which ones you chose. They can still change them later.

### 3. Write the notes (`<Topic>_Connections.md` in the materials folder)
Structure:
1. **Section 0 – Core rules:** the 3–5 principles from which the rest can be derived. This is the most important part. Later "Why?" boxes refer back to them ("Rule 2").
2. **One `##` section per main unit** (e.g. per nerve), numbered. Each contains:
   - A table with the facts (from the sources, including variants like "inconstant" or "or").
   - `**Why?**` paragraphs explaining the connection (course, development, location, cause).
   - `**Mnemonic:**` / `**Mnemonics:**` with memory aids. Only mnemonics that are factually correct.
   - Exceptions and edge cases explained separately ("Why is X supplied twice …?"). Exactly those get tested.
3. **Last section:** a big overview or comparison table (e.g. arm ↔ leg).

**Accuracy:** facts (table contents) come only from the sources. Explanations from general subject knowledge are allowed but must not contradict the sources. If a source differs from the textbook standard, the source wins and the difference is mentioned.

**Format conventions** (recognized by the PDF template):
```markdown
---
title: "Topic<br>Understanding the connections"
kicker: "Module name · Subject"
lang: en                 # language of the notes, e.g. de, fr
toc-title: "Contents"    # for other languages e.g. "Inhalt"
subtitle: "One sentence on what this is about – with the <b>why</b>."
legend:
  - name: "Core rules"
    color: gray
  - name: "Part A"
    color: blue
---

> Short introduction (shown as a blue box).

## 0. The core rules {.gray}
## 1. First part {.blue}
## 2. Still part A            ← no class: inherits the previous colour
## 8. Second part {.green}
```
- Colours: `gray blue green orange purple red teal pink`. One colour per major topic block, listed in `legend`.
- Write YAML lists (`legend`) **indented** (`  - name:`).
- For notes not in English, set `lang`, `toc-title` and the cover labels `why-label` / `mnemonic-label` (e.g. `"Warum-Box"`, `"Eselsbrücke"`) in the language of the notes.
- A paragraph starting with `**Why` becomes a teal box (a directly following list or table is included).
- A paragraph starting with `**Mnemonic` / `**Remember` becomes an orange box (a directly following list or table is included).
- The box keywords must stay in English (`Why`, `Mnemonic`, `Remember`) even when the notes are written in another language, e.g. `**Why?** Weil …`.
- Every `##` section starts on a new page, `###` are subsections.
- `>` quotes become blue info boxes.

### 4. Proofreading
The proofreading instructions are in `study-notes-checker.md` in this skill's folder (installed together with the skill).
- **If your AI tool supports subagents:** start the `study-notes-checker` agent if it is installed, otherwise a general subagent with the content of `study-notes-checker.md` as its task. A fresh agent that did not write the notes finds more errors.
- **If not:** do the check yourself as a separate, deliberate pass that follows `study-notes-checker.md` step by step. Re-read the sources instead of relying on memory.

Give the checker:
- the path to the notes,
- the paths of all source files (`.md`, and for image-only PDFs also the original PDF or the rendered page images),
- which tables you read from page images, so the checker compares them against the images themselves and not against your transcription.

Check its findings and apply the justified corrections. Briefly tell the user what was corrected.

### 5. Build the PDF
Run `build_pdf.sh` from this skill's folder:
```bash
<skill-folder>/build_pdf.sh "<folder>/<Topic>_Connections.md"
```
The PDF is created next to the `.md`. Then check 2–3 pages (`pdftoppm -r 60 -png -f N -l N …` and view the image): tables correct, boxes detected, colours right. If not: fix the Markdown and rebuild.

### 6. Wrap-up
Tell the user: where the `.md` and `.pdf` are, how the notes are structured, what the checker found, and what comes from general knowledge rather than the sources.
Offer: self-test questions with answers at the end, or a more compact print layout.
