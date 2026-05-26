---
name: commit-msg
description: Use this skill when writing or reviewing a git commit message for this repository. Defines allowed tags, format rules and examples.
---

# Commit message convention

All commits follow `[CATEGORY] Description` format. Categories map to the area being changed.

## Area tags

| Tag           | Scope                                                 |
| ------------- | ----------------------------------------------------- |
| `[SHELL]`     | anything under `cli/` (bash, zsh, shared shell layer) |
| `[ZED]`       | `ide/zed/`                                            |
| `[XCODE]`     | `ide/xcode/`                                          |
| `[NANO]`      | `ide/nano/`                                           |
| `[TERMINAL]`  | `terminal/`                                           |
| `[GIT]`       | `tools/git/`                                          |
| `[RECTANGLE]` | `tools/rectangle/`                                    |
| `[CLAUDE]`    | `ai/claude/`                                          |

If a new top-level area is added to the repository, define a new tag for it following the same pattern (uppercase, single word, mapped to a single directory).

## Root-level tags

For changes to files at the repository root:

| Tag           | Scope                                                                                                                 |
| ------------- | --------------------------------------------------------------------------------------------------------------------- |
| `[README]`    | `README.md` only                                                                                                      |
| `[LICENSE]`   | `LICENSE.txt` only                                                                                                    |
| `[GITIGNORE]` | `.gitignore` only                                                                                                     |
| `[PROJECT]`   | two or more root-level files in the same commit                                                                       |
| `[CONFIG]`    | project-level tool configuration: `.claude/`, root config files (`.editorconfig`, `.gitattributes`, `.github/`, etc.) |

## One area per commit

Commit by area. A change that touches `cli/`, `ide/zed/` and `ai/claude/` is **three separate commits**, each with its own area tag, not one commit with a transversal tag. There is no `[REFACTOR]`, `[CHORE]`, or similar catch-all tag. Renames, reorganizations and refactors go under the tag of the affected area.

## Description style

- Imperative mood, capitalized first letter: `Add`, `Update`, `Delete`, `Fix`, `Improve`, `Refactor`, `Rename`, `Restore`. Never past tense (`Added`, `Updated`) or gerund (`Adding`).
- Identifiers (function names, command names, alias names, variable names, file names) in backticks: `` `dos2nix` ``, `` `static-webserver` ``, `` `gitignore` ``.
- Proper names of UI elements (extensions, themes, plugins) in single quotes: `Add extensions: 'Swift Lang'`, `Add Xcode theme - 'Synthwave 84'`.
- Multiple related changes within the same area chained with `&`: ``Improve `dos2nix`, `nix2dos` & `reload-shell` with input validation``. **Always use this pattern** for multiple changes in the same commit. Do not repeat the tag (`[ZED] Add X [ZED] Update Y` is incorrect; write `[ZED] Add X & update Y` instead).
- For trivial changes where the tag is self-explanatory, the description may be omitted: `[LICENSE]`, `[GITIGNORE]`.

## Examples from existing history

```
[SHELL] Defer NVM loading until first use via lazy stub functions
[SHELL] Improve `dos2nix`, `nix2dos` & `reload-shell` with input validation and error handling
[ZED] Add extensions: 'csv', 'rainbow-csv', 'ruby', 'sql'
[XCODE] Add Xcode theme - 'Synthwave 84'
[RECTANGLE] Update configuration - Compatibility with MacOS Sequoia snap windows
[CLAUDE] Create global configuration for personal & professional projects
[GITIGNORE]
```
