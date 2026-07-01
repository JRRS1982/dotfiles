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

# Aliases & helper functions (gp, gc, gcn, dotfiles) — kept in their own file.
[ -f "$HOME/.zsh_aliases" ] && source "$HOME/.zsh_aliases"

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
