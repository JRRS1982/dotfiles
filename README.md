# Dotfiles

Personal config files (`.zshrc`, `.gitconfig`, Claude Code settings/skills) tracked
in one repo and **symlinked** into `$HOME`. Editing the symlinked file edits the
repo — there's nothing to sync, just commit and push.

## How it works (plain English)

A **symlink** ("symbolic link") is a signpost that points at a file living
somewhere else. When a program opens the signpost, it's really opening the file
it points to — think of a shortcut on your desktop, or a mail-forwarding address
that quietly redirects letters to where you actually live.

This repo uses that trick so every machine shares one set of config:

1. The **real** config files live here in this repo (at `~/PersonalProjects/dotfiles`).
2. In your home folder, files like `~/.zshrc` aren't real files — they're
   **signposts pointing back into this repo**.
3. So when your shell reads `~/.zshrc`, it's really reading this repo's copy.
   When you *edit* `~/.zshrc`, you're really editing this repo's copy.

Because the home-folder files are just signposts, there's nothing to copy back
and forth:

> **edit the file where it normally lives → it's already changed in the repo →
> `git push` to publish it → `git pull` on your other computer to receive it.**

One source of truth, no manual syncing. `setup.sh` is the one-time step that puts
those signposts in place on a new machine (next section).

## Set up a new machine

Requires git ≥ 2.36 (needed for `hasconfig`-based identity routing, see below).

```sh
# On a fresh machine without SSH keys yet, use HTTPS:
git clone https://github.com/JRRS1982/dotfiles.git ~/PersonalProjects/dotfiles
# Or use SSH if you already have a GitHub SSH key:
# git clone git@github.com:JRRS1982/dotfiles.git ~/PersonalProjects/dotfiles

cd ~/PersonalProjects/dotfiles
./setup.sh
```

`setup.sh` installs zsh, Oh My Zsh, and nvm, sets up an SSH key if needed, checks
your git version, creates the symlinks below, and creates empty `~/.zshrc.local`
and `~/.claude/CLAUDE.local.md` if they don't exist. It is safe to re-run.

## Adopting on a machine that already has configs

`setup.sh` does **not** assume a brand-new machine. Before linking, any existing
**real** file it would replace (e.g. a pre-existing `~/.zshrc` or `~/.gitconfig`)
is moved to `~/.dotfiles-backup-<timestamp>/` first — nothing is overwritten in
place, and existing correct symlinks are simply repointed.

The backup is **not** auto-merged (symlinking makes the repo's version win). If
those old files had anything worth keeping, fold it in afterwards:

- shared across machines → into the tracked repo files (then commit + push);
- specific to this machine → into `~/.zshrc.local` or `~/.claude/CLAUDE.local.md`.

## Daily use

Because `~/.zshrc` etc. are symlinks into this repo, just edit the file where
it normally lives — you're editing the repo. Then commit and push as usual:

```sh
cd ~/PersonalProjects/dotfiles
git add -A
git commit
git push
```

The `dotfiles` shell alias runs `git` against this repo from anywhere (`dotfiles
status`, `dotfiles add ...`, etc.), so you don't need to `cd` first. For commits,
prefer the `/dotfiles-gc` skill. On another machine, `git pull` in this repo to
get the change.

## What's symlinked

| Repo file | Symlinked to |
|---|---|
| `.zshrc` | `~/.zshrc` |
| `.zsh_aliases` | `~/.zsh_aliases` |
| `.gitconfig` | `~/.gitconfig` |
| `.gitconfig-personal` | `~/.gitconfig-personal` |
| `.gitconfig-work` | `~/.gitconfig-work` |
| `.claude/settings.json` | `~/.claude/settings.json` |
| `.claude/CLAUDE.md` | `~/.claude/CLAUDE.md` |
| `.claude/skills/` | `~/.claude/skills/` |

## Claude Code plugins & MCP servers

Two different mechanisms, reproduced two different ways:

- **Plugins** are *declared* in `.claude/settings.json` (`enabledPlugins`, plus any
  non-official marketplaces under `extraKnownMarketplaces`). The reproduction chain is:
  `setup.sh` symlinks `settings.json` into `~/.claude/` → the next time you launch
  Claude Code it reads `enabledPlugins` and **installs each one from its marketplace**.
  So `setup.sh` has no plugin-specific step — the symlink it already creates is what
  carries them. Two caveats: Claude Code itself must be installed first (`setup.sh`
  does not install it), and the first install from a **non-official** marketplace
  (`thedotmack`, `warpdotdev`, `nextlevelbuilder`, `claude-for-financial-services`)
  may prompt once to trust it.
  The `claude-plugins-official` marketplace is built into Claude Code, so it is
  deliberately **not** listed under `extraKnownMarketplaces` — only the others are.
  Declared in `enabledPlugins` — note that a declaration is not the same as being on;
  the ones marked ❌ stay declared so they are one flag-flip away (the MCP-backed ones
  were switched off in `13d7647` to cut token usage):

  | Plugin | Source | On | What it is |
  |---|---|---|---|
  | `superpowers` | official | ✅ | Skills framework (brainstorming, TDD, systematic-debugging, writing-plans…) |
  | `claude-mem` | `thedotmack` | ✅ | Persistent cross-session memory; bundles the `mcp-search` MCP server |
  | `playwright` | official | ✅ | MCP server for browser automation |
  | `code-simplifier` | official | ✅ | Simplification/refactor agent |
  | `ui-ux-pro-max` | `nextlevelbuilder` | ✅ | UI/UX design skills (styles, palettes, design systems, slides) |
  | `context7` | official | ❌ | MCP server for live, version-accurate library docs |
  | `security-guidance` | official | ❌ | Defensive-security guidance |
  | `explanatory-output-style` | official | ❌ | The "explanatory" output style |
  | `warp` | `warpdotdev` | ❌ | Warp terminal integration |
  | `financial-analysis` | `claude-for-financial-services` | ❌ | DCF / LBO / 3-statement / comps models, competitive analysis, xlsx+pptx authoring |
  | `investment-banking` | `claude-for-financial-services` | ❌ | Client and market insights, deck creation, transaction workflows |
  | `equity-research` | `claude-for-financial-services` | ❌ | Earnings analysis, initiating-coverage reports |
  | `pitch-agent` | `claude-for-financial-services` | ❌ | Comps → precedents → LBO → branded pitch deck, end to end |
  | `market-researcher` | `claude-for-financial-services` | ❌ | Sector/theme → industry overview, peer comps, idea shortlist |
  | `gl-reconciler` | `claude-for-financial-services` | ❌ | GL break detection, root-cause tracing, sign-off routing |

  The six `claude-for-financial-services` plugins come from
  [anthropics/financial-services](https://github.com/anthropics/financial-services)
  (Anthropic's finance vertical: 20 plugins in total, of which these six are declared
  here). They are deliberately **off** — each one loads a large skill set, so leaving
  them enabled burns context on every session. Turn one on only for the session that
  needs it:

  ```bash
  claude plugin enable financial-analysis@claude-for-financial-services
  # ...and back off afterwards
  claude plugin disable financial-analysis@claude-for-financial-services
  ```

  ⚠️ Run `claude plugin enable/disable` from **outside** this repo, or it resolves
  `.claude/settings.json` as *project* settings — which here is the very same file as
  user settings — and edits it in place, showing up as repo drift.

- **Standalone MCP servers** (added via `claude mcp add`) are *not* declared in
  `settings.json` — they live in `~/.claude.json`, which is machine-local and **not**
  symlinked (it also holds per-project history and auth). So they don't travel with
  the repo on their own. `setup.sh` re-registers them on each machine instead:

  | Server | Registered by | Needs |
  |---|---|---|
  | `chrome-devtools` | `setup.sh` (`claude mcp add -s user`) | Node ≥ 22, a local Chrome |

  Note that `context7`, `playwright`, and `claude-mem`'s `mcp-search` are *also* MCP
  servers, but they ride inside plugins (above), so they're already covered by the
  symlinked `settings.json`. Only servers with no plugin wrapper need a `setup.sh` line.

- **Third-party hooks.** `settings.json` also carries a `hooks` block written by
  Orca (`~/.orca/agent-hooks/claude-hook.sh`), wired into
  `UserPromptSubmit`, `Stop`/`StopFailure`, `Subagent{Start,Stop}`, `TeammateIdle`,
  `Pre`/`PostToolUse`, `PostToolUseFailure` and `PermissionRequest`. It is committed
  as-is rather than stripped, so the file stays a faithful copy of what Claude Code
  actually runs. Two things to know: the commands hardcode absolute
  `/home/jeremyadmin/...` paths (unlike the rest of this repo, which is `~`-relative),
  and each is guarded by `[ -f ] && [ -r ] && [ -x ]`, so on a machine without Orca
  they simply no-op. `setup.sh` does **not** install Orca.

  ⚠️ Orca rewrites `~/.claude/settings.json` and has replaced the symlink with a real
  file before, silently detaching it from this repo. If the two look out of sync,
  check `ls -l ~/.claude/settings.json`; re-running `setup.sh` restores the link and
  backs the detached copy up to `~/.dotfiles-backup-*` (fold anything you want to keep
  back into the repo — the backup is not merged for you).

## Machine-local files (never committed)

- `~/.zshrc.local` — machine-specific shell config, sourced at the end of `.zshrc`.
- `~/.claude/CLAUDE.local.md` — machine-specific Claude context, imported by `.claude/CLAUDE.md`.

Both are gitignored and created empty by `setup.sh` — **they are not part of this repo and exist only on the machine you are on**, so you will not find them in this checkout.

## Git identity

`.gitconfig` sets **no default identity** (fail-closed). Identity is chosen per
repo by remote URL via `hasconfig` (git ≥ 2.36):

- Remote matches `JRRS1982` on GitHub → personal identity (`.gitconfig-personal`)
- Remote matches `bitbucket.org:mvfglobal/**` → work identity (`.gitconfig-work`)
- Anything else → git refuses to commit until you set `user.name`/`user.email` yourself

## Adding a skill

Drop it in `~/.claude/skills/<name>/` (i.e. `.claude/skills/<name>/` in this
repo, since it's symlinked). It shows up as untracked in `git status`:

- Shareable → commit it, prefixing the name with `dotfiles-` (e.g. `dotfiles-gc`)
- Private/work-specific → add its path to `.gitignore` instead (e.g. `mvf-jira-writer`)
