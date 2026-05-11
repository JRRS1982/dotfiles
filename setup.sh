#!/usr/bin/env bash
set -e

DOTFILES="$HOME/Repos/dotfiles"
REPO="git@github.com:JRRS1982/dotfiles.git"

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
    mkdir -p "$HOME/Repos"
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
ln -sf "$DOTFILES/.zshrc" "$HOME/.zshrc"
ln -sf "$DOTFILES/.gitconfig" "$HOME/.gitconfig"
mkdir -p "$HOME/.claude"
ln -sf "$DOTFILES/.claude/settings.json" "$HOME/.claude/settings.json"
echo "    ~/.zshrc -> $DOTFILES/.zshrc"
echo "    ~/.gitconfig -> $DOTFILES/.gitconfig"
echo "    ~/.claude/settings.json -> $DOTFILES/.claude/settings.json"

echo ""
echo "Done! Open a new terminal (or run: exec zsh) to start using zsh."
