#!/usr/bin/env bash
# Bootstrap an Ubuntu/WSL dev environment: zsh + antidote + starship, mise-managed tools, dotfiles.
#
#   curl -sSL https://raw.githubusercontent.com/Kamaradeivanov/distro-bootstrap/main/install.sh | bash
#   ./install.sh                  (from a clone)
#
# Idempotent: safe to re-run. Dotfiles are symlinked to the clone, so `git pull` updates them.
set -euo pipefail

REPO_URL="https://github.com/Kamaradeivanov/distro-bootstrap.git"
REPO_DIR="${DISTRO_BOOTSTRAP_DIR:-$HOME/distro-bootstrap}"
WORKSPACE_DIR="$HOME/workspace"
ENABLE_BYOBU="${ENABLE_BYOBU:-0}"   # 1 = launch byobu automatically at login
CONTAINER_RUNTIME="${CONTAINER_RUNTIME:-docker-rootless}"   # docker-rootless | podman

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

[[ $EUID -ne 0 ]] || { echo "Run as your normal user (sudo is called when needed)." >&2; exit 1; }
[[ $CONTAINER_RUNTIME == docker-rootless || $CONTAINER_RUNTIME == podman ]] \
  || { echo "CONTAINER_RUNTIME must be docker-rootless or podman (got: $CONTAINER_RUNTIME)." >&2; exit 1; }

# --- Get the repo (curl | bash mode) ---------------------------------------
# When piped from curl there is no local copy: clone it and re-run from there.
# Until the exec, bash is still reading this script from stdin: nothing here may read stdin.
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
if [[ ! -f $SELF_DIR/config/mise.toml ]]; then
  command -v git >/dev/null || sudo apt-get install -y git </dev/null
  if [[ -d $REPO_DIR/.git ]]; then
    log "Updating $REPO_DIR"
    git -C "$REPO_DIR" pull --ff-only </dev/null
  else
    log "Cloning $REPO_URL into $REPO_DIR"
    git clone "$REPO_URL" "$REPO_DIR" </dev/null
  fi
  exec bash "$REPO_DIR/install.sh" </dev/null
fi
REPO_DIR="$SELF_DIR"

# --- System packages -------------------------------------------------------
log "Installing system packages"
sudo apt-get update -qq
sudo apt-get install -y \
  zsh git curl ca-certificates build-essential unzip \
  fzf jq keychain byobu vim

# --- Container runtime -----------------------------------------------------------
if [[ $CONTAINER_RUNTIME == podman ]]; then
  log "Installing podman"
  sudo apt-get install -y podman
else
  # Docker Engine running as the current user: no root daemon, no docker group
  # (being in the docker group is root-equivalent).
  if [[ ! -f /etc/apt/sources.list.d/docker.sources ]]; then
    log "Adding the Docker apt repository"
    os_id="$(. /etc/os-release && echo "$ID")"
    os_codename="$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")"
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL "https://download.docker.com/linux/$os_id/gpg" -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/$os_id
Suites: $os_codename
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF
    sudo apt-get update -qq
  fi
  log "Installing Docker (rootless)"
  sudo apt-get install -y \
    docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin \
    docker-ce-rootless-extras uidmap dbus-user-session slirp4netns

  # The package starts a rootful daemon: stop it, the rootless setup refuses to run next to it.
  sudo systemctl disable --now docker.service docker.socket 2>/dev/null || true
  sudo rm -f /var/run/docker.sock

  # Ubuntu 24.04+ blocks unprivileged user namespaces unless an AppArmor profile allows them.
  # Recent Ubuntu releases ship one for rootlesskit; add it on those that don't.
  if [[ $(cat /proc/sys/kernel/apparmor_restrict_unprivileged_userns 2>/dev/null) == 1 ]] \
     && ! grep -rqs '/usr/bin/rootlesskit' /etc/apparmor.d/; then
    log "Allowing rootlesskit to create user namespaces (AppArmor)"
    sudo tee /etc/apparmor.d/usr.bin.rootlesskit >/dev/null <<'EOF'
abi <abi/4.0>,
include <tunables/global>

/usr/bin/rootlesskit flags=(unconfined) {
  userns,

  include if exists <local/usr.bin.rootlesskit>
}
EOF
    sudo systemctl restart apparmor.service
  fi

  if systemctl --user show-environment >/dev/null 2>&1; then
    if [[ ! -f $HOME/.config/systemd/user/docker.service ]]; then
      log "Setting up the rootless Docker daemon"
      dockerd-rootless-setuptool.sh install
    fi
    systemctl --user enable --now docker.service
    # Keep the daemon (and restart: unless-stopped containers) running without an open session.
    sudo loginctl enable-linger "$USER"
    # For tools started outside zsh (IDE, desktop apps); zsh also exports DOCKER_HOST (.zshenv).
    docker context use rootless >/dev/null
  else
    log "No systemd user session (WSL without systemd?): run dockerd-rootless-setuptool.sh install once it is enabled"
  fi
fi

# --- antidote (zsh plugin manager) -------------------------------------------
# Plugins listed in config/.zsh_plugins.txt are fetched on the first zsh start.
if [[ ! -d $HOME/.antidote ]]; then
  log "Installing antidote"
  git clone --depth 1 https://github.com/mattmc3/antidote.git "$HOME/.antidote"
fi

# --- Dotfiles ----------------------------------------------------------------
# Existing regular files are kept as <file>.bak-<date> before being replaced by a symlink.
link() {
  local src="$REPO_DIR/$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [[ -e $dst && ! -L $dst ]]; then
    mv "$dst" "$dst.bak-$(date +%Y%m%d%H%M%S)"
  fi
  ln -sfn "$src" "$dst"
  echo "  $dst -> $src"
}
log "Linking dotfiles"
link config/.zshenv       "$HOME/.zshenv"
link config/.zshrc        "$HOME/.zshrc"
link config/.zsh_aliases  "$HOME/.zsh_aliases"
link config/.zsh_plugins.txt "$HOME/.zsh_plugins.txt"
link config/mise.toml     "$HOME/.config/mise/config.toml"
link config/starship.toml "$HOME/.config/starship.toml"

# git: include the shared settings; ~/.gitconfig keeps the identity and local overrides.
if ! git config --global --get-all include.path | grep -qxF "$REPO_DIR/config/gitconfig"; then
  git config --global --add include.path "$REPO_DIR/config/gitconfig"
  echo "  ~/.gitconfig includes $REPO_DIR/config/gitconfig"
fi

# --- mise and tools ------------------------------------------------------------
export PATH="$HOME/.local/bin:$PATH"
if ! command -v mise >/dev/null; then
  log "Installing mise"
  curl -fsSL https://mise.run | sh
fi
log "Installing tools from config/mise.toml"
mise install --yes

# krew plugins listed in config/krew-plugins.txt. mise ships the binary as `krew`;
# the `krew` plugin itself provides `kubectl krew` (used by the kk alias).
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
mapfile -t wanted < <(sed -e 's/#.*//' -e 's/[[:space:]]//g' -e '/^$/d' "$REPO_DIR/config/krew-plugins.txt")
mapfile -t installed < <(mise exec -- krew list 2>/dev/null)
missing=()
for plugin in krew "${wanted[@]}"; do
  printf '%s\n' "${installed[@]}" | grep -qx "$plugin" || missing+=("$plugin")
done
if ((${#missing[@]})); then
  log "Installing krew plugins: ${missing[*]}"
  mise exec -- krew update
  mise exec -- krew install "${missing[@]}"
else
  log "krew plugins already installed (upgrade them with: kubectl krew upgrade)"
fi

# --- Workspace -------------------------------------------------------------------
mkdir -p "$WORKSPACE_DIR"

# --- byobu -----------------------------------------------------------------------
mkdir -p "$HOME/.byobu"
grep -qx 'set -g mouse on' "$HOME/.byobu/.tmux.conf" 2>/dev/null \
  || echo 'set -g mouse on' >> "$HOME/.byobu/.tmux.conf"
[[ $ENABLE_BYOBU == 1 ]] && byobu-enable

# --- Default shell ---------------------------------------------------------------
zsh_path="$(command -v zsh)"
if [[ $(getent passwd "$USER" | cut -d: -f7) != "$zsh_path" ]]; then
  log "Setting zsh as default shell"
  sudo chsh -s "$zsh_path" "$USER"
  shell_changed=1
fi

# First zsh start: antidote fetches the plugins, completions get cached.
log "Warming up zsh (plugins, completions)"
zsh -i -c exit </dev/null >/dev/null 2>&1 || true

if [[ ${shell_changed:-0} == 1 || ${SHELL:-} != "$zsh_path" ]]; then
  log "Done. Log out and back in so new terminals start zsh (meanwhile: exec zsh)."
else
  log "Done. Open a new terminal (or run: exec zsh)."
fi
