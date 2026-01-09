#!/bin/bash

# Exit on error
set -e

# Variables
REPO_MAIN_RAW_URL="https://raw.githubusercontent.com/Kamaradeivanov/distro-bootstrap/refs/heads/main"
CONFIG_DIR="$HOME/distro-bootstrap"
WORKSPACE_DIR="$HOME/workspace"
TOOL_VERSIONS_URL="$REPO_MAIN_RAW_URL/.tool-versions"
ZSH_ALIASES_URL="$REPO_MAIN_RAW_URL/.zsh_aliases"
ZSH_RC_URL="$REPO_MAIN_RAW_URL/.zshrc"

# Install system dependencies
echo "Installation des dépendances système..."
sudo apt update
sudo apt install -y zsh git curl build-essential unzip direnv fzf jq yq

# Install oh-my-zsh if not exist
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installation de oh-my-zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Install asdf version 0.18.0 if not install
# Check if version 0.18.0 is already install
if ! asdf --version | grep -q "0.18.0"; then
  wget https://github.com/asdf-vm/asdf/releases/download/v0.18.0/asdf-v0.18.0-linux-amd64.tar.gz
  mkdir -p ${HOME}/.local/bin
  tar -xvzf asdf-v0.18.0-linux-amd64.tar.gz -C ${HOME}/.local/bin
  chmod +x ${HOME}/.local/bin/asdf
  mkdir -p "${ASDF_DATA_DIR:-$HOME/.asdf}/completions"
  export PATH="$HOME/.local/bin:$PATH"
  asdf completion zsh > "${ASDF_DATA_DIR:-$HOME/.asdf}/completions/_asdf"
fi

# Télécharger et installer les outils depuis .tool-versions
echo "Téléchargement de la liste des outils..."
curl -sSL "$TOOL_VERSIONS_URL" | while read -r line; do
  # Ignorer les lignes vides et les commentaires
  if [[ -n "$line" && ! "$line" =~ ^[[:space:]]*# ]]; then
    tool_name=$(echo "$line" | awk '{print $1}')
    tool_version=$(echo "$line" | awk '{print $2}')
    echo "Installation de $tool_name version $tool_version..."

    # Installer le plugin asdf si nécessaire (simplifié)
    if ! asdf plugin list | grep -q "$tool_name"; then
      asdf plugin add "$tool_name"
    fi

    # Install a specific version
    asdf install "$tool_name" "$tool_version"
    asdf set --home "$tool_name" "$tool_version"
  fi
done

# Lier les fichiers de configuration
echo "Copy files..."
wget $ZSH_ALIASES_URL -O .zsh_aliases
wget $ZSH_RC_URL -O .zshrc

# Créer le workspace et configurer direnv
echo "Configuration du workspace..."
mkdir -p "$WORKSPACE_DIR"
cd "$WORKSPACE_DIR"
touch .envrc
direnv allow .

# Set zsh as a default shell
chsh -s $(which zsh)

# Enable mouse mode in tmux (byobu)
mkdir -p ~/.byobu
echo "set -g mouse on" > ~/.byobu/.tmux.conf

# Switch to zsh
echo "Switching to zsh..."
exec zsh
byobu-enable

# Install krew plugin kubectx and kubens
kk install ctx
kk install ns

echo "Installation complete ! You can now open a new terminal."
