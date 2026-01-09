# distro-bootstrap 🚀

**Automate your Ubuntu/WSL development environment setup with zsh, asdf, direnv, and more!**

This repository provides a **one-command setup** for a fully configured development environment, including:

- **zsh + Oh My Zsh** (with plugins)
- **asdf** (for managing tool versions)
- **direnv** (for project-specific environments)
- **Pre-configured tools** (kubectl, helm, terraform, nodejs, python, etc.)
- **Workspace organization** (per-client directories)

---

## ✨ Features

- **One-command install**: Just run `curl -sSL https://raw.githubusercontent.com/Kamaradeivanov/distro-bootstrap/main/install.sh | bash`
- **Customizable**: Edit `.tool-versions` to add/remove tools.
- **Portable**: Works on Ubuntu, WSL, and most Debian-based systems.
- **Idempotent**: Safe to re-run (won’t break existing setups).

---

## 📥 Installation

### 1. Run the install script

```bash
curl -sSL https://raw.githubusercontent.com/Kamaradeivanov/distro-bootstrap/main/install.sh | bash
```

### 2. Restart your terminal

```bash
exec zsh
```

### 3. Verify the setup

```bash
asdf list
direnv version
```

---

## 🛠 Customization

### Add/Remove Tools

Edit the [`.tool-versions`](config/.tool-versions) file to specify which tools and versions to install. Example:

```bash
kubectl 1.28.4
helm 3.14.0
terraform 1.6.6
nodejs 20.11.1
```

### Update Tools

To update a tool, edit `.tool-versions` and re-run:

```bash
asdf install <tool> <version>
asdf global <tool> <version>
```

---

## 📂 Project Structure

```tree
distro-bootstrap/
├── install.sh          # Main install script (executable via curl)
├── config/              # Configuration files
│   ├── .zshrc           # Zsh configuration
│   ├── .tool-versions   # List of tools and versions
│   ├── .asdfrc          # asdf configuration
│   └── .direnv/         # direnv scripts
└── README.md            # This file
```

---

## 🔧 Requirements

- Ubuntu/WSL (or any Debian-based system)
- `curl`, `git`, and `sudo` access

---

## 🤝 Contributing

Pull requests are welcome! For major changes, please open an issue first.
