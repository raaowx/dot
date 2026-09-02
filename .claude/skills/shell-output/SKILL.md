---
name: shell-output
description: Use this skill when writing or reviewing any user-facing message in the shell layer (cli/). Defines the colour taxonomy, message levels, emitters, prompts and startup output.
---

# Shell output convention

**The colour marks the level, the text is read in white.** The tag (`[ERROR]`, `[WARN]`, `[OK]`) or the marker (`··>`) carries the level colour; the body of the message is always `$WB`; variable data inside the body is highlighted.

This keeps the level legible even where the palette is not recalibrated, because the level is always identified by a textual tag and never by colour alone.

## Levels

| Level | Tag | Tag colour | Body | Stream |
| ------- | --------- | ---------- | ----- | ------ |
| Error   | `[ERROR]` | `$RB`      | `$WB` | stderr |
| Warning | `[WARN]`  | `$YB`      | `$WB` | stderr |
| Success | `[OK]`    | `$GB`      | `$WB` | stdout |
| Info    | `··>`     | `$WB`      | `$WB` | stdout |

Errors and warnings go to **stderr** so that redirecting stdout does not swallow them.

## Emitters

Defined in `cli/shell/messages.shell`. Use them instead of hand-writing `echo -e`:

```bash
shell-error "File not found: $1"
shell-warn  "Could not fetch from remote, comparing against local refs"
shell-ok    "Removed worktree:$MB $short"
shell-info  "Branch: master"
```

They live in their own file, sourced right after `variables.shell` and **before any output is produced**, because `profile.shell` prints its startup messages long before `functions.shell` is loaded.

Messages with emphasis interleaved mid-sentence stay as plain `echo -e`, since `$*` cannot express a colour change in the middle of a phrase:

```bash
echo -e "$WB ··> Branch:$CB $branch$WB (new, from$CB $target$WB)$RESET"
```

## Palette

Measured against the terminal background `#393939`. All eight pass WCAG AA 4.5:1.

| Colour | Hex | Ratio | Role |
| ------------- | --------- | ---- | ---------------------------------------- |
| `$WB` white   | `#E9EBEB` | 9.65 | Message body, `··>` marker               |
| `$YB` yellow  | `#EAEC23` | 9.09 | `[WARN]` tag                             |
| `$CB` cyan    | `#00E5E5` | 7.34 | Emphasised values, startup items         |
| `$GB` green   | `#31E722` | 6.92 | `[OK]` tag, prompt success status        |
| `$AB` blue    | `#A894FF` | 4.59 | Prompt structure, suggested commands     |
| `$RB` red     | `#FD7C6B` | 4.55 | `[ERROR]` tag, prompt error status       |
| `$MB` magenta | `#E970FF` | 4.52 | Paths and file names                     |
| `$BB` grey    | `#A0A2A2` | 4.50 | Muted secondary text                     |

**Values, paths and commands.** Inside a message body, use `$CB` for values (branches, counters, names, hosts) and `$MB` for anything that is a filesystem path or file name. `[DIR]` and `[FILE]` tags are path labels and therefore `$MB`.

A **suggested command** — one the user is meant to copy and run — goes entirely in `$AB`, including any path it contains: the copyable unit weighs more than its parts, and a single colour is what makes it recognisable as one. `$AB` is used because it is the only colour with no other role inside a message body, so the command stands apart from the values and paths on the surrounding lines.

**Muted text.** `$BB` is for secondary detail that accompanies another message — never for information the user must read to understand what happened.

**Never use the non-bright variants** (`$B $R $G $Y $A $M $C $W`) as foreground in messages: several are illegible on this background and the rest are dimmer versions of a bright that already does the job. They remain declared for use as **background** colours (`\033[4Xm`) with bright text on top, and in the prompts.

**Known limitation:** cyan and green have almost identical luminance (ratio 1.06), so inside an `[OK]` message the emphasis is distinguished by hue rather than brightness.

## Terminal palette recalibration

`terminal/macos/macos.terminal` overrides five ANSI slots so the palette meets AA. If a slot is changed there, update the table above.

| Slot | Default | Ratio | Override | Ratio |
| ------------------------ | --------- | ---- | --------- | ---- |
| `ANSIBrightRedColor`     | `#FC391F` | 3.16 | `#FD7C6B` | 4.55 |
| `ANSIBrightMagentaColor` | `#F935F8` | 3.79 | `#E970FF` | 4.52 |
| `ANSIBrightBlueColor`    | `#5833FF` | 1.83 | `#A894FF` | 4.59 |
| `ANSIBrightBlackColor`   | `#818383` | 3.03 | `#A0A2A2` | 4.50 |
| `ANSIBrightCyanColor`    | —         | —    | `#00E5E5` | 7.34 |

Magenta is shifted to violet (hue 291°) rather than merely lightened: lightening alone left it at the same luminance as the new red, and both appear on the same line in `[ERROR] ... /a/path`.

These slots are also used by `git`, `grep`, `ls` and compilers, so the change is wider than the shell layer. In a terminal without this profile the defaults return — which is why the textual tag, not the colour, is what identifies the level.

## Formatting rules

- The leading space goes **inside** the coloured span: `"$RB [ERROR]"`, never `" $RB[ERROR]"`.
- Every coloured span closes with `$RESET`, **with no space before it**.
- The level is never encoded by colour alone; the tag or glyph always identifies it.
- No trailing period on single-sentence messages.
- `··>` is reserved for INFO messages and for `PS2`. It is not a list bullet and does not appear in banners.

## Interactive prompts

Message with `··>`, options indented five spaces when present, and always `  > ` on its own line before the `read`:

```
··> Delete it? [y/n]
  > _

··> .gitignore already exists
     [b] Create a backup and continue
     [c] Cancel
  > _
```

## Startup output

The startup uses the same vocabulary as any other message: header as an info line, loaded items highlighted as values.

```
Hi raaowx! Welcome to zsh 5.9

··> Loading completion:
   · git
   · docker

··> Loading scripts:
   · aliases
   · functions
```

Banner in `$CB` with no glyph, header via `shell-info`, items with `·` in `$CB` on a `$WB` bullet.

## Prompts

`PS1`/`PS2`/`RPS1` follow the same taxonomy: structure in `$AB`, values in `$CB`, working directory in `$MB`, exit status in `$GB`/`$RB`.

`$AB` therefore carries two roles — prompt structure and suggested commands — and the context tells them apart: one only ever appears in a prompt, the other only inside a message body. Neither can be mistaken for the other on screen.

Zsh keeps the numeric `%F{n}` codes instead of the palette variables: raw escape sequences would need `%{...%}` wrapping for zsh to compute the prompt width, and getting that wrong corrupts the prompt. Correspondence: 9↔`$RB`, 10↔`$GB`, 12↔`$AB`, 13↔`$MB`, 14↔`$CB`, 15↔`$WB`.

In bash, `$?` must be captured as the **first** element of `PROMPT_COMMAND`, before anything else overwrites it.

## Exempt from this convention

`ai/claude/hooks/` and `.claude/hooks/` emit JSON or plain text consumed by Claude Code, not by the terminal. Colour there would be incorrect; they write to stderr without ANSI sequences.

## Examples from existing code

```bash
shell-error "Refusing to create a worktree for the base branch '$branch'"
shell-warn "'$target' has no upstream branch"
shell-ok "Removed worktree:$MB $short"
shell-info "Loading scripts:"

echo -e "$WB ··> Repository:$CB $repo$WB →$MB ${main_entry#*	}$RESET"
echo -e "$WB ··>$MB [DIR]$WB  $MB$dir$RESET"
echo -e "$WB ··> Enter it with:$AB cd \"$hint\"$RESET"
echo -e "$WB   ·$CB git$RESET"
```
