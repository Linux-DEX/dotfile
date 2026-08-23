#!/usr/bin/env bash
#
# install-arch.sh
# Sets up an Arch Linux machine to match https://github.com/Linux-DEX/dotfile
# (This is also the config's "native" distro — .zshrc has ArcoLinux/pacman aliases.)
#
# Installs: zsh + oh-my-zsh, starship, neovim (latest), vim + vim-plug,
#           tmux + TPM, zellij, GNU stow, modern CLI (eza, bat, fd, ripgrep,
#           fzf, zoxide, lazygit, git-delta, yazi, fastfetch), terminal
#           emulators (alacritty, kitty, wezterm, ghostty), Zed editor,
#           JetBrains Mono Nerd Font, and (optionally) docker/go/rust/bun/kubectl.
#           Finally clones the dotfiles repo and symlinks everything with stow.
#
# Usage:
#   chmod +x install-arch.sh
#   ./install-arch.sh              # full install
#   ./install-arch.sh --no-dev     # skip docker/go/rust/bun/kubectl
#   ./install-arch.sh --no-stow    # install tools only, don't touch dotfiles
#
set -euo pipefail

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
DOTFILES_REPO="https://github.com/Linux-DEX/dotfile.git"
DOTFILES_DIR="$HOME/.dotfiles"
BIN_DIR="$HOME/.local/bin"
WITH_DEV_TOOLS=true
WITH_STOW=true

for arg in "$@"; do
  case "$arg" in
    --no-dev) WITH_DEV_TOOLS=false ;;
    --no-stow) WITH_STOW=false ;;
    --help|-h)
      grep '^#' "$0" | sed 's/^#//'
      exit 0
      ;;
  esac
done

mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:/usr/local/bin:$PATH"

# ---------------------------------------------------------------------------
# Logging helpers
# ---------------------------------------------------------------------------
c_reset='\033[0m'; c_blue='\033[1;34m'; c_green='\033[1;32m'; c_yellow='\033[1;33m'; c_red='\033[1;31m'
info()  { echo -e "${c_blue}[INFO]${c_reset} $*"; }
ok()    { echo -e "${c_green}[ OK ]${c_reset} $*"; }
warn()  { echo -e "${c_yellow}[WARN]${c_reset} $*"; }
err()   { echo -e "${c_red}[FAIL]${c_reset} $*" >&2; }
has()   { command -v "$1" >/dev/null 2>&1; }

if [[ $EUID -eq 0 ]]; then
  err "Don't run this as root. Run as your normal user; it will call sudo when needed."
  exit 1
fi
if ! has sudo; then
  err "sudo is required but not found. Install sudo first (as root: pacman -S sudo)."
  exit 1
fi

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64) GH_ARCH="x86_64"; NVIM_ARCH="linux-x86_64" ;;
  aarch64|arm64) GH_ARCH="aarch64"; NVIM_ARCH="linux-arm64" ;;
  *) err "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# ---------------------------------------------------------------------------
# 0. AUR helper (paru) — several tools here (yazi, ghostty on older Arch,
#    tmux-plugin extras) are easiest via AUR; official repos cover most though.
# ---------------------------------------------------------------------------
install_paru() {
  if has paru; then ok "paru already installed"; return; fi
  info "Installing paru (AUR helper)..."
  sudo pacman -S --needed --noconfirm base-devel git
  local tmp; tmp="$(mktemp -d)"
  git clone -q https://aur.archlinux.org/paru-bin.git "$tmp/paru-bin"
  (cd "$tmp/paru-bin" && makepkg -si --noconfirm)
  rm -rf "$tmp"
  ok "paru installed"
}

# ---------------------------------------------------------------------------
# 1. Base system packages (pacman — Arch repos are current enough that almost
#    everything here comes straight from `extra`, unlike Debian/Fedora)
# ---------------------------------------------------------------------------
install_base_packages() {
  info "Updating pacman..."
  sudo pacman -Syu --noconfirm

  info "Installing core packages..."
  sudo pacman -S --needed --noconfirm \
    base-devel curl wget git unzip zip tar gnupg \
    zsh vim neovim tmux stow jq tree \
    fontconfig ttf-jetbrains-mono-nerd xclip wl-clipboard \
    python python-pip python-pipx \
    xdg-utils
  ok "Core packages installed"

  # Arch repos are current, but package names DO occasionally change (e.g. p7zip -> 7zip).
  # pacman aborts the *entire* transaction if any one target isn't found, so install
  # the rest one at a time to keep a single renamed/missing package from blocking everything.
  info "Installing modern CLI + app packages (best-effort per package)..."
  local pkgs=(ripgrep fzf bat fd zoxide eza starship lazygit git-delta fastfetch zellij \
              7zip unrar most alacritty kitty wezterm ghostty)
  for pkg in "${pkgs[@]}"; do
    sudo pacman -S --needed --noconfirm "$pkg" \
      && ok "$pkg installed" \
      || warn "$pkg not found in your repos/mirrors — check https://archlinux.org/packages/?q=$pkg for the current name"
  done
}

# ---------------------------------------------------------------------------
# 2. zsh + oh-my-zsh + plugins (fixes the /opt/homebrew paths in .zshrc,
#    which only exist on macOS — we install the plugins as oh-my-zsh
#    custom plugins instead, which is the standard Linux layout)
# ---------------------------------------------------------------------------
install_zsh() {
  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    info "Installing oh-my-zsh..."
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  else
    ok "oh-my-zsh already installed"
  fi
  local custom="$HOME/.oh-my-zsh/custom/plugins"
  mkdir -p "$custom"
  [[ -d "$custom/zsh-autosuggestions" ]] || git clone -q https://github.com/zsh-users/zsh-autosuggestions "$custom/zsh-autosuggestions"
  [[ -d "$custom/zsh-syntax-highlighting" ]] || git clone -q https://github.com/zsh-users/zsh-syntax-highlighting "$custom/zsh-syntax-highlighting"
  ok "zsh plugins cloned into oh-my-zsh custom/plugins (the .zshrc source paths get auto-patched to match — see setup_dotfiles below)"
}

# ---------------------------------------------------------------------------
# 3. Neovim — pacman's `extra/neovim` is usually recent, but this config
#    needs the built-in vim.pack manager (0.12+); fall back to the latest
#    upstream release tarball if the repo package is older.
# ---------------------------------------------------------------------------
install_neovim() {
  if has nvim && nvim --version | head -1 | grep -qE 'v0\.(1[2-9]|[2-9][0-9])'; then
    ok "Neovim already up to date (from pacman)"
    return
  fi
  info "pacman's neovim is older than needed — installing latest release directly..."
  local tmp; tmp="$(mktemp -d)"
  curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/nvim-${NVIM_ARCH}.tar.gz" -o "$tmp/nvim.tar.gz"
  sudo rm -rf /opt/nvim
  sudo mkdir -p /opt/nvim
  sudo tar -xzf "$tmp/nvim.tar.gz" -C /opt/nvim --strip-components=1
  sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
  rm -rf "$tmp"
  ok "Neovim installed: $(nvim --version | head -1)"
}

install_vim_plug() {
  if [[ -f "$HOME/.vim/autoload/plug.vim" ]]; then ok "vim-plug already installed"; return; fi
  info "Installing vim-plug..."
  curl -fsSLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  ok "vim-plug installed (run :PlugInstall inside vim after stowing)"
}

# ---------------------------------------------------------------------------
# 4. Anything left that's AUR-only (yazi typically also has an `extra` package
#    now, but keep a paru fallback for older mirrors) + Zed editor
# ---------------------------------------------------------------------------
install_extras() {
  if ! has yazi; then
    info "Installing yazi..."
    sudo pacman -S --needed --noconfirm yazi 2>/dev/null || paru -S --noconfirm --skipreview yazi
  else ok "yazi already installed"; fi

  if ! has zed; then
    info "Installing Zed editor..."
    curl -fsSL https://zed.dev/install.sh | sh
  else ok "zed already installed"; fi
}

# ---------------------------------------------------------------------------
# 5. tmux plugin manager
# ---------------------------------------------------------------------------
install_tpm() {
  local tpm_dir="$HOME/.config/tmux/.tmux/plugins/tpm"
  if [[ -d "$tpm_dir" ]]; then ok "TPM already installed"; return; fi
  info "Installing tmux plugin manager (TPM)..."
  git clone -q https://github.com/tmux-plugins/tpm "$tpm_dir"
  ok "TPM installed (open tmux and press prefix + I to install plugins)"
}

# ---------------------------------------------------------------------------
# 6. Editor/shell runtimes — NOT optional even though they look like "dev tools":
#    .zshrc unconditionally runs `export PATH=$PATH:$(go env GOPATH)/bin` with no
#    existence check, so a missing `go` breaks every shell startup with a visible
#    error. Node is needed for half of Mason's ensure_installed LSP list (ts_ls,
#    html, cssls, tailwindcss, emmet_ls, eslint) to install successfully.
#    So these always run, regardless of --no-dev.
# ---------------------------------------------------------------------------
install_editor_runtimes() {
  sudo pacman -S --needed --noconfirm nodejs npm go \
    || warn "nodejs/npm/go install had issues — Mason LSP installs and 'go env GOPATH' in .zshrc may fail"
}

# ---------------------------------------------------------------------------
# 7. Optional dev tooling used only by .zshrc aliases (docker, kubectl) or
#    that fail gracefully if absent (rust, bun) — safe to skip with --no-dev
# ---------------------------------------------------------------------------
install_dev_tools() {
  local dev_pkgs=(rustup docker docker-compose kubectl)
  for pkg in "${dev_pkgs[@]}"; do
    sudo pacman -S --needed --noconfirm "$pkg" \
      && ok "$pkg installed" \
      || warn "$pkg not found — check https://archlinux.org/packages/?q=$pkg for the current name"
  done
  if ! has cargo; then
    rustup default stable
  fi
  if ! has bun; then
    info "Installing Bun..."
    curl -fsSL https://bun.sh/install | bash
  else ok "bun already installed"; fi

  sudo systemctl enable --now docker
  sudo usermod -aG docker "$USER"
  warn "Log out/in (or run 'newgrp docker') for the docker group change to take effect"
}

# ---------------------------------------------------------------------------
# 8. Clone dotfiles and symlink with GNU stow
# ---------------------------------------------------------------------------
setup_dotfiles() {
  if [[ -d "$DOTFILES_DIR" ]]; then
    info "Dotfiles repo already present at $DOTFILES_DIR, pulling latest..."
    git -C "$DOTFILES_DIR" pull --ff-only \
      || warn "Couldn't fast-forward $DOTFILES_DIR (local edits from a previous run of this script?) — using what's on disk"
  else
    info "Cloning dotfiles repo..."
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  fi

  # The repo's .zshrc has *unguarded* `source /opt/homebrew/share/...` lines for
  # zsh-autosuggestions/zsh-syntax-highlighting — that's a macOS Homebrew path with
  # no [ -f ... ] check, so it throws a visible "no such file" error on every shell
  # start on Linux. Point it at the oh-my-zsh custom plugin dirs we installed into instead.
  if grep -q '/opt/homebrew/share/zsh-autosuggestions' "$DOTFILES_DIR/.zshrc" 2>/dev/null; then
    info "Patching .zshrc: macOS Homebrew plugin paths -> Linux oh-my-zsh custom plugin paths..."
    cp "$DOTFILES_DIR/.zshrc" "$DOTFILES_DIR/.zshrc.bak"
    sed -i "s#/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh#$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh#" "$DOTFILES_DIR/.zshrc"
    sed -i "s#/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh#$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh#" "$DOTFILES_DIR/.zshrc"
    ok "Patched (original saved as $DOTFILES_DIR/.zshrc.bak). This edits the file inside your cloned repo — review/commit it there if you want to keep the change."
  fi

  # Stow REFUSES to link anything if the target already exists as a real file —
  # and .bashrc/.gitconfig/.vimrc almost always already exist on a fresh install,
  # and oh-my-zsh's own installer (run earlier in this script) creates ~/.zshrc if
  # one wasn't already there. Back up anything in the way before stowing.
  info "Checking for existing dotfiles that would block stow..."
  local backup_dir="$HOME/.dotfiles-backup-$(date +%Y%m%d%H%M%S)"
  ( cd "$DOTFILES_DIR" && find . -maxdepth 1 -mindepth 1 \
      ! -name '.git' ! -name '.stow-local-ignore' ! -name '.gitignore' ! -name 'scripts' \
      ! -name 'README*' ! -name 'LICENSE*' -printf '%f\n' ) | while read -r item; do
    local target="$HOME/$item"
    if [[ -e "$target" && ! -L "$target" ]]; then
      mkdir -p "$backup_dir"
      warn "$target already exists — moving it to $backup_dir/ so stow can link the dotfiles version"
      mv "$target" "$backup_dir/"
    fi
  done
  [[ -d "$backup_dir" ]] && ok "Pre-existing dotfiles backed up to $backup_dir"

  info "Symlinking dotfiles into \$HOME with stow..."
  cd "$DOTFILES_DIR"
  stow --target="$HOME" --restow .
  ok "Dotfiles linked"

  # fzf-git.sh, used by the fzf key-bindings in .zshrc
  [[ -d "$HOME/fzf-git.sh" ]] || git clone -q https://github.com/junegunn/fzf-git.sh.git "$HOME/fzf-git.sh"
}

set_default_shell() {
  if [[ "$SHELL" != *"zsh"* ]]; then
    info "Setting zsh as your default shell (you'll need to log out/in)..."
    sudo chsh -s "$(command -v zsh)" "$USER"
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  install_paru
  install_base_packages
  install_zsh
  install_neovim
  install_vim_plug
  install_extras
  install_tpm
  install_editor_runtimes
  $WITH_DEV_TOOLS && install_dev_tools || warn "Skipping optional dev tools (--no-dev): rust, bun, docker, kubectl"
  $WITH_STOW && setup_dotfiles || warn "Skipping dotfiles stow (--no-stow)"
  set_default_shell

  echo
  ok "All done!"
  echo "Next steps:"
  echo "  1. Log out/in (or reboot) so the zsh/docker group changes apply."
  echo "  2. Set your terminal font to 'JetBrainsMono Nerd Font' (installed via ttf-jetbrains-mono-nerd)."
  echo "  3. Open tmux and press: Ctrl-A then I   -> installs tmux plugins (TPM)."
  echo "  4. Open nvim and run: :PackUpdate       -> installs Neovim plugins."
  echo "  5. Open vim and run: :PlugInstall       -> installs classic-vim plugins."
}

main "$@"
