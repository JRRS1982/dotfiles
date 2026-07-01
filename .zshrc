# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="agnoster"

# Which plugins would you like to load?
plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

# WHAT: Start prompt on a new line
# WHY: So the prompt is always on the left when you're looking for it
PROMPT=$'\n'$PROMPT

# JS: gp helper
# WHAT: push the local branch to the remote origin (creating upstream if needed)
# WHY: makes life easier by reducing typing.
# HOW: i.e. "gp"
unalias gp 2>/dev/null
gp() {
  local branch=$(git rev-parse --abbrev-ref HEAD)
  if git ls-remote --exit-code --heads origin "$branch" &>/dev/null; then
    echo "Branch '$branch' already exists on the remote. Pushing updates..."
  else
    echo "Branch '$branch' does not exist on the remote. Creating it now..."
  fi
  git push --set-upstream origin "$branch"
}

# JS: gc helper
# WHAT: commit all staged changes, prefixing the message with the branch name.
# WHY: makes life easier
# HOW: i.e. "gc add new button" on branch GOLD-123 -> "GOLD-123: add new button"
unalias gc 2>/dev/null
gc() {
  branch=$(git rev-parse --abbrev-ref HEAD)
  git commit -m "$branch: $*"
}

# JS: gcn helper — like gc but skips pre-commit hooks
unalias gcn 2>/dev/null
gcn() {
  branch=$(git rev-parse --abbrev-ref HEAD)
  git commit -n -m "$branch: $*"
}

# WHAT: alias to manage the dotfiles repo from anywhere
# WHY: quick add/commit of tracked config
# HOW: dotfiles status | dotfiles add ~/.zshrc | dotfiles commit -m "..."
alias dotfiles="git -C $HOME/PersonalProjects/dotfiles"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"  # bun completions

# Machine-specific overrides (work paths, tool launchers, version-pinned aliases).
# Not tracked in the repo — created per-machine by setup.sh.
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
