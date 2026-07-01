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
