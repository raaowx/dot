# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

A personal dotfiles repository for macOS (Apple Silicon). Configurations are stored here as a backup and versioned reference; there is no automated install script — files are placed manually at their target locations.

## No build, lint, or test pipeline

This is a declarative configuration repository. There are no build commands, test suites, or linters.

## Repository structure

```
.
├── ai/claude/        Claude Code profiles (personal & professional)
├── cli/
│   ├── bash/         Bash-specific RC
│   ├── shell/        Shell-agnostic layer sourced by both bash and zsh
│   └── zsh/          Zsh-specific RC
├── ide/
│   ├── nano/         Nano editor config
│   ├── xcode/        Xcode themes, key bindings, screenshots
│   └── zed/          Zed editor config and extensions
├── terminal/macos/   Terminal.app profile
└── tools/
    ├── git/          Global git config and ignore rules
    └── rectangle/    Rectangle window manager config
```

## Commit message convention

All commits follow `[CATEGORY] Description` format. Categories map to the area being changed.

### Area tags

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

### Root-level tags

For changes to files at the repository root:

| Tag           | Scope                                                                                                                 |
| ------------- | --------------------------------------------------------------------------------------------------------------------- |
| `[README]`    | `README.md` only                                                                                                      |
| `[LICENSE]`   | `LICENSE.txt` only                                                                                                    |
| `[GITIGNORE]` | `.gitignore` only                                                                                                     |
| `[PROJECT]`   | two or more root-level files in the same commit                                                                       |
| `[CONFIG]`    | project-level tool configuration: `.claude/`, root config files (`.editorconfig`, `.gitattributes`, `.github/`, etc.) |

### One area per commit

Commit by area. A change that touches `cli/`, `ide/zed/` and `ai/claude/` is **three separate commits**, each with its own area tag, not one commit with a transversal tag. There is no `[REFACTOR]`, `[CHORE]`, or similar catch-all tag. Renames, reorganizations and refactors go under the tag of the affected area.

### Description style

- Imperative mood, capitalized first letter: `Add`, `Update`, `Delete`, `Fix`, `Improve`, `Refactor`, `Rename`, `Restore`. Never past tense (`Added`, `Updated`) or gerund (`Adding`).
- Identifiers (function names, command names, alias names, variable names, file names) in backticks: `` `dos2nix` ``, `` `static-webserver` ``, `` `gitignore` ``.
- Proper names of UI elements (extensions, themes, plugins) in single quotes: `Add extensions: 'Swift Lang'`, `Add Xcode theme - 'Synthwave 84'`.
- Multiple related changes within the same area chained with `&`: `Improve `dos2nix`, `nix2dos`&`reload-shell` with input validation`. **Always use this pattern** for multiple changes in the same commit. Do not repeat the tag (`[ZED] Add X [ZED] Update Y` is incorrect; write `[ZED] Add X & update Y` instead).
- For trivial changes where the tag is self-explanatory, the description may be omitted: `[LICENSE]`, `[GITIGNORE]`.

### Examples from existing history

```
[SHELL] Defer NVM loading until first use via lazy stub functions
[SHELL] Improve `dos2nix`, `nix2dos` & `reload-shell` with input validation and error handling
[ZED] Add extensions: 'csv', 'rainbow-csv', 'ruby', 'sql'
[XCODE] Add Xcode theme - 'Synthwave 84'
[RECTANGLE] Update configuration - Compatibility with MacOS Sequoia snap windows
[CLAUDE] Create global configuration for personal & professional projects
[GITIGNORE]
```

## Shell layer (`cli/`)

### Sourcing chain

The shell config has a deliberate sourcing chain. Understanding it is required to know which file to edit:

```
~/.zshrc  →  cli/zsh/rc.zsh
               ├── sources cli/shell/init.shell
               │     └── sources cli/shell/variables.shell
               │           (sets Homebrew path, locale, ANSI colors, tool paths)
               ├── sources cli/shell/profile.shell
               │     (zsh options, prompts, history, NVM lazy-load, completions)
               ├── sources cli/shell/aliases.shell
               └── sources cli/shell/functions.shell  (utility functions)
```

`cli/bash/` mirrors the same chain for bash. The `cli/shell/` layer is shell-agnostic and sourced by both.

### Naming and ordering in `cli/shell/`

These conventions apply to all files under `cli/shell/` (`aliases.shell`, `functions.shell`):

- **Alphabetical order**, enforced by single-letter section comments (A, B, C, …). When adding a new entry, place it in its corresponding letter section and respect the alphabetical sort within that section.
- **Kebab-case for multi-word identifiers**: `add-space-to-dock`, `kill-procs-on-volume`, `static-webserver`. Never `addSpaceToDock` or `add_space_to_dock`.

### Cross-platform compatibility

Functions and aliases in `cli/shell/` should aim for compatibility with Linux distributions (Ubuntu, Debian, Zorin, Arch, …) in addition to macOS, since the shared layer is meant to be portable.

This is a goal, not a hard requirement: if compatibility is not possible or significantly increases complexity, the macOS-only path is acceptable. Some existing entries may not meet this goal and that is fine; the convention applies to new additions and to changes on existing entries.

When a function or alias relies on macOS-only commands (`pbcopy`, `open`, `osascript`, `launchctl`, etc.), prefer detecting the platform at runtime and falling back to the Linux equivalent (`xclip`/`wl-copy`, `xdg-open`, `notify-send`, `systemctl`, etc.) over making the whole entry macOS-only.

Bash-specific (`cli/bash/`) and zsh-specific (`cli/zsh/`) files are exempt from this goal — they are intentionally shell-specific. Platform-specific behavior should live in the shell-agnostic layer (`cli/shell/`).

## Claude profiles

`ai/claude/` holds two profiles — `personal` and `professional` — each as a `.md` (behavioral instructions) + `.json` (Claude Code settings). They share the same base behavior; the professional variant relaxes the personal-projects language constraint (which forces Swift for scripting and CLIs as a deliberate learning goal) and instead lets the agent pick the most efficient language for the project's stack. Both disable telemetry and restrict destructive git and filesystem operations.

These files are the source of truth for `~/.claude/CLAUDE.md` and `~/.claude/settings.json` (global) or project-level equivalents. They are copied manually to their target locations; this repository does not symlink or install them automatically.

## Platform assumptions

All configurations target macOS on Apple Silicon. Homebrew is expected at `/opt/homebrew`. Shell scripts may reference macOS-specific commands (`pbcopy`, `open`, `osascript`, `launchctl`); see [Cross-platform compatibility](#cross-platform-compatibility) for how to handle these.
