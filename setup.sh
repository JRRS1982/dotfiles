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
# Safe to run on a machine that already has real config files, and safe to
# re-run: any existing NON-symlink target is moved into $BACKUP_DIR before we
# link over it, so nothing is destroyed. Existing correct symlinks are just
# repointed. If you had customisations in the backed-up files, fold what you
# want to keep into the repo (shared) or into ~/.zshrc.local /
# ~/.claude/CLAUDE.local.md (machine-specific) afterwards.
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

# link SRC DST — make DST a symlink pointing at SRC, without ever destroying data.
# Handles the three states DST can be in:
#   1. DST is already a symlink        -> repoint it at SRC (makes re-runs safe)
#   2. DST is a real file or directory -> move it into $BACKUP_DIR, then link
#      (this is what protects a machine that already had its own config)
#   3. DST does not exist              -> just create the link
link() {
    local src="$1" dst="$2"
    if [ -L "$dst" ]; then
        # Case 1: DST is already a symlink -> just repoint it (idempotent re-run).
        ln -sfn "$src" "$dst"
    elif [ -e "$dst" ]; then
        # Case 2: DST is a real file/dir -> move it to the backup dir before linking,
        # so a machine's pre-existing config is preserved, never overwritten in place.
        mkdir -p "$BACKUP_DIR"
        mv "$dst" "$BACKUP_DIR/"
        echo "    backed up existing $dst -> $BACKUP_DIR/"
        ln -sfn "$src" "$dst"
    else
        # Case 3: nothing at DST -> create the link.
        ln -sfn "$src" "$dst"
    fi
}

mkdir -p "$HOME/.claude"
link "$DOTFILES/.zshrc"                "$HOME/.zshrc"
link "$DOTFILES/.zsh_aliases"          "$HOME/.zsh_aliases"
link "$DOTFILES/.gitconfig"            "$HOME/.gitconfig"
link "$DOTFILES/.gitconfig-personal"   "$HOME/.gitconfig-personal"
link "$DOTFILES/.gitconfig-work"       "$HOME/.gitconfig-work"
link "$DOTFILES/.claude/settings.json" "$HOME/.claude/settings.json"
link "$DOTFILES/.claude/CLAUDE.md"     "$HOME/.claude/CLAUDE.md"
link "$DOTFILES/.claude/skills"        "$HOME/.claude/skills"
echo "    Linked: .zshrc, .zsh_aliases, .gitconfig(+personal/work), .claude/{settings.json,CLAUDE.md,skills}"
[ -d "$BACKUP_DIR" ] && echo "    NOTE: pre-existing files were backed up to $BACKUP_DIR"

echo "==> Bootstrapping machine-local files (not tracked)..."
[ -f "$HOME/.zshrc.local" ]           || { touch "$HOME/.zshrc.local"; echo "    created ~/.zshrc.local (add machine-specific config here)"; }
[ -f "$HOME/.claude/CLAUDE.local.md" ] || { touch "$HOME/.claude/CLAUDE.local.md"; echo "    created ~/.claude/CLAUDE.local.md (add machine-specific Claude context here)"; }

echo ""
echo "Done! Open a new terminal (or run: exec zsh) to start using zsh."
