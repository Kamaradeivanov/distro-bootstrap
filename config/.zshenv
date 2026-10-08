# Ubuntu's /etc/zsh/zshrc runs compinit before ~/.zshrc, with an fpath that lacks our
# completion cache; the dump it writes is then reused by `compinit -C`. Skip it.
skip_global_compinit=1

# Rootless Docker (set up by install.sh): the daemon socket lives in the user runtime dir.
[[ -f ~/.config/systemd/user/docker.service ]] && export DOCKER_HOST="unix://${XDG_RUNTIME_DIR:-/run/user/$UID}/docker.sock"
