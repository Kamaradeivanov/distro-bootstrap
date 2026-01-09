### Path configuration ###

export PATH="$HOME/.local/bin:${KREW_ROOT:-$HOME/.krew}/bin:/usr/local/bin:$PATH"
export PATH="$PATH:$HOME/.pulumi/bin"
export PATH="$PATH:$HOME/bin"
export PATH="$PATH:$HOME/.tfenv/bin"
export PATH="$PATH:$HOME/.cargo/bin"
export PATH="$PATH:$HOME/.asdf/bin:$HOME/.asdf/shims"
export PATH="$GOPATH/bin:$GOROOT/bin:$PATH"
export GOROOT=/usr/local/go
export GOPATH=$HOME/go

### Oh my ZSH configuration ###

export ZSH=$HOME/.oh-my-zsh
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="bureau"
plugins=(
  asdf
  aws
  command-not-found
  direnv
  docker
  fzf
  git
  git-flow
  helm
  kube-ps1
  kubectl
  npm
  pip
  screen
  ubuntu
  zsh-autosuggestions
  zsh-interactive-cd
)
ENABLE_CORRECTION="true"
source $ZSH/oh-my-zsh.sh
source ~/.zsh_aliases

### Shell options ###

setopt correct
export PROMPT_EOL_MARK=''
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
export GPG_TTY=$(tty)

### Completions ###

autoload -Uz compinit && compinit -C
source <(kubectl completion zsh)
kubectl completion zsh > "${fpath[1]}/_kubectl"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
eval "$(scw autocomplete script shell=zsh)"
source <(werf completion --shell=zsh)

### Version Managers ###
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] &&  "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] &&  "$NVM_DIR/bash_completion"

### PNPM ###
export PNPM_HOME="/home/ivanov/.local/share/pnpm"
[[ ":$PATH:" != ":$PNPM_HOME:" ]] && export PATH="$PNPM_HOME:$PATH"

### SSH Agent ###
eval $(ssh-agent)
eval `keychain --eval ssh ~/.ssh/ibeaute ~/.ssh/fabrique-it`
# ssh-add ~/.ssh/ibeaute 2>/dev/null
# ssh-add ~/.ssh/fabrique-it 2>/dev/null

### Direnv (Per-project environments) ###
eval "$(direnv hook zsh)"

# ### Werf (if installed) ###
! { which werf | grep -qsE "^/home/ivanov/.trdl/"; } && [[ -x "$HOME/bin/trdl" ]] && source $("HOME/bin/trdl" use werf "1.2" "stable")

### Prompt Customization ###
PROMPT='$(kube_ps1)'$PROMPT

autoload -Uz compinit && compinit
