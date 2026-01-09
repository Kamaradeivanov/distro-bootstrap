# distro-bootstrap 🚀

**Automate your Ubuntu/WSL development environment setup with zsh, [starship](https://starship.rs) and [mise](https://mise.jdx.dev).**

This repository provides a **one-command setup** for a fully configured development environment:

- **zsh** without a framework: [antidote](https://antidote.sh) loads a few plugins (fzf-tab, autosuggestions, syntax highlighting), shell starts in well under 100 ms
- **starship** prompt with kube context/namespace, git and gcloud project
- **Git aliases** with the oh-my-zsh names (`gst`, `gco`, `gpsup`, `glog`…) — see [`config/.zsh_aliases`](config/.zsh_aliases)
- **mise** — tool versions (replaces asdf) and per-directory environment variables (replaces direnv)
- **Pre-configured tools**: kubectl, helm, k9s, krew + kubectl plugins (ctx, ns, cnpg, stern, neat…), opentofu, terragrunt, gcloud, scw, glab, gh, node…
- **Dotfiles** symlinked from this repo: `git pull` is enough to update them

---

## 📥 Installation

```bash
curl -sSL https://raw.githubusercontent.com/Kamaradeivanov/distro-bootstrap/main/install.sh | bash
```

This clones the repo into `~/distro-bootstrap` (override with `DISTRO_BOOTSTRAP_DIR`) and runs it from there.
From an existing clone, just run `./install.sh`.

Then open a new terminal (or `exec zsh`) and check:

```bash
mise doctor
mise ls
```

Options (environment variables):

| Variable | Default | Effect |
|---|---|---|
| `DISTRO_BOOTSTRAP_DIR` | `~/distro-bootstrap` | where the repo is cloned in `curl \| bash` mode |
| `ENABLE_BYOBU` | `0` | `1` = start byobu automatically at login |

The script is **idempotent**: re-run it any time. Existing dotfiles are kept as `<file>.bak-<date>` before being replaced by symlinks.

---

## 🛠 Customization

### Tools

Global tools live in [`config/mise.toml`](config/mise.toml) (symlinked to `~/.config/mise/config.toml`).

```bash
mise outdated          # what can be upgraded
# bump the version in config/mise.toml, then:
mise install
```

### Per-project tools and environment

Drop a `mise.toml` in any directory (e.g. one per client under `~/workspace`):

```toml
[tools]
kubectl = "1.33"

[env]
KUBECONFIG = "{{config_root}}/.kube/config"
_.file = ".env"        # load a .env file
```

Run `mise trust` once in that directory. Existing `.tool-versions` files are still read by mise.

### kubectl plugins

Listed in [`config/krew-plugins.txt`](config/krew-plugins.txt); add a line and re-run `./install.sh`.
`kubectl krew upgrade` updates them.

### Git

[`config/gitconfig`](config/gitconfig) is included from `~/.gitconfig` (which keeps your name/e-mail):
vim as editor, `git difftool` / `git mergetool` open vimdiff, conflicts shown in `zdiff3` style.

### Shell plugins and prompt

- zsh plugins: [`config/.zsh_plugins.txt`](config/.zsh_plugins.txt), then open a new shell
- prompt: [`config/starship.toml`](config/starship.toml) ([docs](https://starship.rs/config/))
- `antidote update` updates the plugins

---

## 🔁 Migrating from the oh-my-zsh/asdf/direnv version

1. Pull and re-run `./install.sh`.
2. Remove oh-my-zsh: `rm -rf ~/.oh-my-zsh`.
3. Remove asdf: `rm -rf ~/.asdf ~/.local/bin/asdf`.
4. Convert `.envrc` files: plain `export FOO=bar` lines become `[env]` entries in a `mise.toml`;
   anything more complex can stay in a script loaded with `_.source = "script.sh"`.
5. Remove direnv: `sudo apt remove direnv`.

Aliases from oh-my-zsh plugins other than git (kubectl, ubuntu…) are not carried over: add the ones you use to `config/.zsh_aliases`.

---

## 📂 Project Structure

```tree
distro-bootstrap/
├── install.sh           # Main install script (works via curl | bash)
├── config/
│   ├── mise.toml        # Global tools and versions
│   ├── krew-plugins.txt # kubectl plugins (krew)
│   ├── .zshrc           # Zsh configuration
│   ├── .zsh_aliases     # Aliases (git, kubectl, tofu…)
│   ├── .zsh_plugins.txt # zsh plugins (antidote)
│   ├── starship.toml    # Prompt
│   └── gitconfig        # Shared git settings (vim as editor/diff/merge tool)
└── README.md
```

---

## 🔧 Requirements

- Ubuntu/WSL (or any Debian-based system), x86_64 or arm64
- `curl` and `sudo` access

---

## 🤝 Contributing

Pull requests are welcome! For major changes, please open an issue first.
