# Ubuntu's /etc/zsh/zshrc runs compinit before ~/.zshrc, with an fpath that lacks our
# completion cache; the dump it writes is then reused by `compinit -C`. Skip it.
skip_global_compinit=1
