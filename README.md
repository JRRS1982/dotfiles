# Dotfiles

Your terminal config files (`.zshrc`, `.gitconfig`, etc.) live in `$HOME` but are a pain to back up and move between machines. This repo solves that by keeping them all in one git repo and using **symlinks** to put them where the system expects them.

**What's a symlink?** Think of it as a shortcut. `~/.zshrc` looks like a normal file to everything that uses it, but it's actually just a pointer to `~/Repos/dotfiles/.zshrc`. Edit either one and you're editing the same file — so there's nothing to copy or sync. Just commit and push.

---

## Setting up a new machine

Open a terminal and run:

```sh
bash <(curl -fsSL https://raw.githubusercontent.com/JRRS1982/dotfiles/master/setup.sh)
```

This downloads the setup script and runs it. You don't need SSH set up yet — it uses HTTPS to fetch the script first.

The script will walk you through:

1. Installing `zsh`, `git`, and `gh` (the GitHub CLI) — requires Fedora/dnf
2. Setting zsh as your default shell
3. Installing Oh My Zsh (a zsh config framework)
4. Generating an SSH key and pausing so you can add it to GitHub
5. Cloning this repo to `~/Repos/dotfiles`
6. Installing NVM (Node version manager) and the latest LTS version of Node
7. Creating all the symlinks

> **Broken characters in your prompt?** The `agnoster` theme needs a Nerd Font installed and selected in your terminal's font settings. Grab one from [nerdfonts.com](https://www.nerdfonts.com) — JetBrainsMono Nerd Font is a safe pick.

---

## Day-to-day usage

A `dotfiles` alias is set up in `.zshrc`. It's just `git`, but always pointing at this repo — so you can run it from anywhere:

```sh
dotfiles status                        # see what's changed
dotfiles diff                          # see the actual changes
dotfiles add .zshrc                    # stage a file
dotfiles commit -m "Update zshrc"
dotfiles push
dotfiles pull                          # pull changes on another machine
```

Or just `cd ~/Repos/dotfiles` and use regular `git` — same thing.

---

## Adding a new file to track

1. Copy the file into the repo
2. Replace the original with a symlink pointing at the repo copy
3. Commit it

```sh
cp ~/.config/starship.toml ~/Repos/dotfiles/.config/starship.toml
ln -sf ~/Repos/dotfiles/.config/starship.toml ~/.config/starship.toml
dotfiles add .config/starship.toml
dotfiles commit -m "Track starship config"
dotfiles push
```

---

## Machine-specific git config

`~/.gitconfig` is tracked here and sets your default name and email. If you need different values on a specific machine (e.g. a work email), create `~/.gitconfig.local` — it gets loaded automatically and is never committed to this repo:

```ini
[user]
    email = jeremy@work.com
```

---

## Files tracked

| File in repo | Where it's symlinked |
|---|---|
| `.zshrc` | `~/.zshrc` |
| `.gitconfig` | `~/.gitconfig` |
| `.claude/settings.json` | `~/.claude/settings.json` |
