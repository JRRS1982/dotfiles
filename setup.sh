#!/usr/bin/env bash
set -e

DOTFILES="$HOME/PersonalProjects/dotfiles"
REPO="git@github.com:JRRS1982/dotfiles.git"

echo "==> Checking git version (hasconfig identity routing needs >= 2.36)..."
NEED="2.36.0"
HAVE="$(git --version | awk '{print $3}')"
if [ "$(printf '%s\n%s\n' "$NEED" "$HAVE" | sort -V | head -1)" != "$NEED" ]; then
    echo "    ERROR: git $HAVE found; need >= $NEED for hasconfig. Upgrade git first." >&2
    exit 1
fi
echo "    git $HAVE OK."

echo "==> Installing zsh, git, and gh..."
sudo dnf install -y zsh git gh

echo "==> Setting zsh as default shell..."
if [ "$SHELL" != "$(which zsh)" ]; then
    chsh -s "$(which zsh)"
    echo "    Default shell changed — log out and back in after setup completes."
else
    echo "    Already set to zsh."
fi

echo "==> Installing Oh My Zsh..."
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "    Already installed."
else
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

echo "==> Checking SSH key..."
if [ ! -f "$HOME/.ssh/id_ed25519" ] && [ ! -f "$HOME/.ssh/id_rsa" ]; then
    echo "    No SSH key found. Generating one..."
    ssh-keygen -t ed25519 -C "jeremyrrsmith@gmail.com" -f "$HOME/.ssh/id_ed25519" -N ""
    echo "    Add this public key to GitHub before continuing:"
    echo ""
    cat "$HOME/.ssh/id_ed25519.pub"
    echo ""
    read -r -p "    Press Enter once the key is added to GitHub..."
else
    echo "    SSH key found."
fi

echo "==> Cloning dotfiles repo..."
if [ -d "$DOTFILES/.git" ]; then
    echo "    Already cloned."
else
    mkdir -p "$HOME/PersonalProjects"
    git clone "$REPO" "$DOTFILES"
fi

echo "==> Installing NVM..."
if [ -d "$HOME/.nvm" ]; then
    echo "    Already installed."
else
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/HEAD/install.sh | bash
fi

echo "==> Installing LTS Node via NVM..."
export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
if command -v nvm &>/dev/null; then
    nvm install --lts
    nvm use --lts
else
    echo "    NVM not found in current shell — run 'nvm install --lts' manually after restarting."
fi

echo "==> Creating symlinks..."
ln -sf  "$DOTFILES/.zshrc"                 "$HOME/.zshrc"
ln -sf  "$DOTFILES/.zsh_aliases"           "$HOME/.zsh_aliases"
ln -sf  "$DOTFILES/.gitconfig"             "$HOME/.gitconfig"
ln -sf  "$DOTFILES/.gitconfig-personal"    "$HOME/.gitconfig-personal"
ln -sf  "$DOTFILES/.gitconfig-work"        "$HOME/.gitconfig-work"
mkdir -p "$HOME/.claude"
ln -sf  "$DOTFILES/.claude/settings.json"  "$HOME/.claude/settings.json"
ln -sf  "$DOTFILES/.claude/CLAUDE.md"      "$HOME/.claude/CLAUDE.md"
ln -sfn "$DOTFILES/.claude/skills"         "$HOME/.claude/skills"
echo "    Linked: .zshrc, .zsh_aliases, .gitconfig(+personal/work), .claude/{settings.json,CLAUDE.md,skills}"

echo "==> Bootstrapping machine-local files (not tracked)..."
[ -f "$HOME/.zshrc.local" ]           || { touch "$HOME/.zshrc.local"; echo "    created ~/.zshrc.local (add machine-specific config here)"; }
[ -f "$HOME/.claude/CLAUDE.local.md" ] || { touch "$HOME/.claude/CLAUDE.local.md"; echo "    created ~/.claude/CLAUDE.local.md (add machine-specific Claude context here)"; }

echo ""
echo "Done! Open a new terminal (or run: exec zsh) to start using zsh."
