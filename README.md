# Dotfiles.git

This is my attempt at implementing the `bare git` repository method for managing the dotfiles on my personal laptop, i.e. no working directory / files in the local project (including this readme!).

Dotfiles are configuration files, I want to store them in a remote git repository in case my local machine fails and i lose them. With this approach your dotfiles remain on your computer in `$HOME` (e.g. `~/.zshrc`) on your machine, and git metadata lives in `$HOME/.dotfiles.git`, so that it can be tracked and saved to the remote repo.

The git metadata is tracking the files are outside of this repository so you will not see any files in this project locally. The `work-tree` is `$HOME` (where your dotfiles typically belong) and the `git-dir` is `$HOME/.dotfiles.git` (where the git metadata lives).

## Setup

Prerequisites: git, zsh or bash

For convenience i use an alias for commands, using a mapping from this project (`--git-dir=$HOME/.dotfiles.git`) to `$HOME` (`--work-tree=$HOME`).

i.e. this alias should be in your .zshrc or .bashrc file: `alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles.git --work-tree=$HOME'`.

For the alias to work you will need to clone the repo into a directory called `$HOME/.dotfiles.git` or update the alias to point to the correct directory.

### Clone existing repo to a new machine

```sh
# Clone the repo
git clone --bare https://github.com/JRRS1982/dotfiles "$HOME/.dotfiles.git"
# Use repo to update the files in your working directory (i.e. $HOME)
dotfiles checkout
# Configure to ignore untracked files
dotfiles config --local status.showUntrackedFiles no
```

If `dotfiles checkout` reports existing files would be overwritten, move them out of the way and retry the checkout.

### Create a new dotfiles bare repo (i.e. your own repo)

```sh
# Create the repo
git init --bare "$HOME/.dotfiles.git"
# Create the alias for your terminal session (or add this to your .zshrc or .bashrc file for persistence)
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles.git --work-tree=$HOME'
# Configure to ignore untracked files
dotfiles config --local status.showUntrackedFiles no
```

Then add a remote and push:

```sh
dotfiles remote add origin https://github.com/JRRS1982/dotfiles
dotfiles push -u origin master
```

### Day-to-day usage

Check status and diffs:

```sh
dotfiles status
dotfiles diff -- ~/.zshrc
```

Track a new file or update an existing one:

```sh
dotfiles add ~/.zshrc
dotfiles commit -m "Update zshrc"
dotfiles push
```

Pull changes on another machine:

```sh
dotfiles pull
```

## Thanks to

- <https://web.archive.org/web/20240307132655/https://engineeringwith.kalkayan.com/series/developer-experience/storing-dotfiles-with-git-this-is-the-way/> for a detailed explanation of this method 
- <https://askubuntu.com/questions/1316229/is-it-bad-practice-to-git-init-in-the-home-directory-to-keep-track-of-dot-files/1316230#comment2240922_1316230> where i learnt that bare git repositories typically end in `.git`, hence this repository is called `.dotfiles.git`
- <https://askubuntu.com/questions/1316229/is-it-bad-practice-to-git-init-in-the-home-directory-to-keep-track-of-dot-files/1316230#1316230> where i learnt how to setup a bare git repository
- <https://news.ycombinator.com/item?id=11071754> where i read more about bare git repositories
- <https://coffeeaddict.dev/how-to-manage-dotfiles-with-git-bare-repo/> this article for guarding against the `git add .` command by using a `.gitignore` file with `*` by default.
