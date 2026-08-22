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
               ├── sources cli/shell/messages.shell  (message emitters)
               ├── sources cli/shell/aliases.shell
               └── sources cli/shell/functions.shell  (utility functions)
```

`messages.shell` is sourced by `profile.shell` immediately after `variables.shell` and **before any output is produced**. That ordering is deliberate: the startup prints its own messages long before `functions.shell` is loaded, so the emitters cannot live there.

`cli/bash/` mirrors the same chain for bash. The `cli/shell/` layer is shell-agnostic and sourced by both.

### Naming and ordering in `cli/shell/`

These conventions apply to all files under `cli/shell/` (`aliases.shell`, `functions.shell`):

- **Alphabetical order**, enforced by single-letter section comments (A, B, C, …). When adding a new entry, place it in its corresponding letter section and respect the alphabetical sort within that section.
- **Kebab-case for multi-word identifiers**: `add-space-to-dock`, `kill-procs-on-volume`, `static-webserver`. Never `addSpaceToDock` or `add_space_to_dock`.

### Message output

All user-facing output from `cli/` follows a single convention: the colour marks the level, the body is read in white, errors and warnings go to stderr, and the emitters in `cli/shell/messages.shell` (`shell-error`, `shell-warn`, `shell-ok`, `shell-info`) are used instead of hand-written `echo -e`.

The full rules — colour taxonomy, contrast ratios, prompt shapes and startup format — live in the `shell-output` skill (`.claude/skills/shell-output/SKILL.md`).

### Cross-platform compatibility

Functions and aliases in `cli/shell/` should aim for compatibility with Linux distributions (Ubuntu, Debian, Zorin, Arch, …) in addition to macOS, since the shared layer is meant to be portable.

This is a goal, not a hard requirement: if compatibility is not possible or significantly increases complexity, the macOS-only path is acceptable. Some existing entries may not meet this goal and that is fine; the convention applies to new additions and to changes on existing entries.

When a function or alias relies on macOS-only commands (`pbcopy`, `open`, `osascript`, `launchctl`, etc.), prefer detecting the platform at runtime and falling back to the Linux equivalent (`xclip`/`wl-copy`, `xdg-open`, `notify-send`, `systemctl`, etc.) over making the whole entry macOS-only.

Bash-specific (`cli/bash/`) and zsh-specific (`cli/zsh/`) files are exempt from this goal — they are intentionally shell-specific. Platform-specific behavior should live in the shell-agnostic layer (`cli/shell/`).

## Claude profiles

`ai/claude/` holds two profiles — `personal` and `professional` — each as a `.md` (behavioral instructions) + `.json` (Claude Code settings). They share the same base behavior; the professional variant relaxes the personal-projects language constraint (which forces Swift for scripting and CLIs as a deliberate learning goal) and instead lets the agent pick the most efficient language for the project's stack. Both disable telemetry and restrict destructive git and filesystem operations.

These files are the source of truth for `~/.claude/CLAUDE.md` and `~/.claude/settings.json` (global) or project-level equivalents. They are copied manually to their target locations; this repository does not symlink or install them automatically.

`ai/claude/hooks/` holds the scripts referenced from the `hooks` section of both `.json` profiles, and is the source of truth for `~/.claude/hooks/`. They must be copied there with the executable bit set.

Access to sensitive files is enforced in two layers, and both must be kept in sync by hand when either changes:

- `permissions.deny` / `permissions.ask` in the `.json` profiles, which only cover the `Read` tool. `deny` is reserved for paths that are never source code (`.env`, `secrets/**`, `~/.ssh`, crypto material extensions); name patterns that frequently match legitimate code (`*credential*`, `*secret*`) live in `ask` instead, so files like `credentials.js` prompt rather than being blocked outright.
- `hooks/guard-bash-read.sh`, a `PreToolUse` hook matching `Bash`, which applies the same two pattern sets to paths extracted from the command line. It exists because `permissions` does not intercept Bash, so `cat .env` would otherwise bypass the rules entirely. Its pattern lists are deliberately duplicated from the `.json` profiles rather than shared. It degrades to allowing the command when `jq` is missing or the payload is unparseable, to avoid breaking every Bash call in a session.

## Platform assumptions

All configurations target macOS on Apple Silicon. Homebrew is expected at `/opt/homebrew`. Shell scripts may reference macOS-specific commands (`pbcopy`, `open`, `osascript`, `launchctl`); see [Cross-platform compatibility](#cross-platform-compatibility) for how to handle these.

The Terminal.app profile in `terminal/macos/macos.terminal` overrides five ANSI bright slots so that every colour used by the shell layer meets WCAG AA against its background. Those slots are shared with `git`, `grep`, `ls` and compilers, so changing them affects more than the shell; the ratios and rationale are documented in the `shell-output` skill.
