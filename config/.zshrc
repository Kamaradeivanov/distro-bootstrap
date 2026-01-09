### Path configuration ###

export GOPATH="$HOME/go"
export PATH="$HOME/.local/bin:$HOME/bin:${KREW_ROOT:-$HOME/.krew}/bin:$GOPATH/bin:$HOME/.cargo/bin:$PATH"

### mise (tool versions + per-directory env) ###
# hook-env puts the tools in PATH right away, so the completions below find them.

if (( $+commands[mise] )); then
  eval "$(mise activate zsh)"
  eval "$(mise hook-env -s zsh)"
fi

### History ###

HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt extended_history hist_expire_dups_first hist_ignore_dups hist_ignore_space hist_verify share_history

### Shell options ###

setopt auto_cd auto_pushd pushd_ignore_dups pushdminus interactive_comments correct
export EDITOR=vim VISUAL=vim
export PROMPT_EOL_MARK=''
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
export GPG_TTY=$(tty)

### Key bindings (emacs mode) ###

bindkey -e
autoload -U up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search    # Up: history search on typed prefix
bindkey '^[OA' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[OB' down-line-or-beginning-search
bindkey '^[[1;5C' forward-word                # Ctrl+Right
bindkey '^[[1;5D' backward-word               # Ctrl+Left
bindkey '^[[H' beginning-of-line              # Home
bindkey '^[[F' end-of-line                    # End
bindkey '^[[3~' delete-char                   # Delete

### Completions ###
# Tool completions are generated once into a cache and refreshed when the tool binary changes.

zcomp_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completions"
mkdir -p "$zcomp_dir"
fpath=("$zcomp_dir" $fpath)

zcomp_new=0
_zcomp_cache() {  # _zcomp_cache <tool> <command that prints the zsh completion...>
  local tool=$1 out="$zcomp_dir/_$1"; shift
  (( $+commands[$tool] )) || return 0
  [[ -s $out && $out -nt ${commands[$tool]} ]] && return 0
  "$@" >| "$out" 2>/dev/null && zcomp_new=1
}
_zcomp_cache kubectl  kubectl completion zsh
_zcomp_cache helm     helm completion zsh
_zcomp_cache gh       gh completion -s zsh
_zcomp_cache glab     glab completion -s zsh
_zcomp_cache argocd   argocd completion zsh
_zcomp_cache k9s      k9s completion zsh
_zcomp_cache mise     mise completion zsh
_zcomp_cache podman   podman completion zsh
unfunction _zcomp_cache

# Full compinit when a completion changed or once a day; otherwise reuse the dump (fast path).
autoload -Uz compinit
zcomp_stale=(~/.zcompdump(N.mh+24))
if (( zcomp_new || ${#zcomp_stale} )) || [[ ! -s ~/.zcompdump ]]; then
  compinit
else
  compinit -C
fi
unset zcomp_new zcomp_stale

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' menu no                                    # fzf-tab takes over
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -1 --color=always $realpath'

# tofu completes through bash-style `complete -C`
autoload -U +X bashcompinit && bashcompinit
(( $+commands[tofu] )) && complete -o nospace -C "${commands[tofu]}" tofu

# scw: same as `scw autocomplete script`, minus its extra compinit and absolute-path compdef
_scw() {
  local -a output opts=(-S ' ')
  output=($(scw autocomplete complete zsh -- ${CURRENT} ${words}))
  [[ $output == *= ]] && opts=(-S '')
  compadd "${opts[@]}" -- "${output[@]}"
}
compdef _scw scw

### Plugins (antidote) ###

if [[ -r ~/.antidote/antidote.zsh ]]; then
  source ~/.antidote/antidote.zsh
  antidote load ~/.zsh_plugins.txt
fi

### Integrations ###

(( $+commands[fzf] )) && source <(fzf --zsh)                       # Ctrl+R, Ctrl+T, Alt+C
[[ -r /etc/zsh_command_not_found ]] && source /etc/zsh_command_not_found

### Aliases ###

source ~/.zsh_aliases

### SSH Agent ###
# Load every private key in ~/.ssh that has a matching .pub.

if (( $+commands[keychain] )); then
  ssh_keys=(~/.ssh/*.pub(N:r))
  (( ${#ssh_keys} )) && eval "$(keychain --eval --quiet $ssh_keys)"
  unset ssh_keys
fi

### Prompt ###

(( $+commands[starship] )) && eval "$(starship init zsh)"
