#!/usr/bin/env bash
#
# install-fedora.sh
# Sets up a Fedora machine to match https://github.com/Linux-DEX/dotfile
#
# Installs: zsh + oh-my-zsh, starship, neovim (latest), vim + vim-plug,
#           tmux + TPM, zellij, GNU stow, modern CLI (eza, bat, fd, ripgrep,
#           fzf, zoxide, lazygit, git-delta, yazi, fastfetch), terminal
#           emulators (alacritty, kitty, wezterm, ghostty via COPR), Zed editor,
#           JetBrains Mono Nerd Font, and (optionally) docker/go/rust/bun/kubectl.
#           Finally clones the dotfiles repo and symlinks everything with stow.
#
# Usage:
#   chmod +x install-fedora.sh
#   ./install-fedora.sh              # full install
#   ./install-fedora.sh --no-dev     # skip docker/go/rust/bun/kubectl
#   ./install-fedora.sh --no-stow    # install tools only, don't touch dotfiles
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
  err "sudo is required but not found. Install sudo first (as root: dnf install sudo)."
  exit 1
fi

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64) GH_ARCH="x86_64"; NVIM_ARCH="linux-x86_64" ;;
  aarch64|arm64) GH_ARCH="aarch64"; NVIM_ARCH="linux-arm64" ;;
  *) err "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# ---------------------------------------------------------------------------
# Generic helper: download a binary/archive from the latest GitHub release
# and drop the extracted binary into $BIN_DIR. Used for tools that aren't
# reliably packaged (or are outdated) in Fedora's repos.
# ---------------------------------------------------------------------------
gh_install() {
  local name="$1" repo="$2" asset_pattern="$3" binary_in_archive="$4"
  if has "$name"; then ok "$name already installed, skipping"; return; fi
  info "Installing $name from GitHub releases ($repo)..."
  local tmp; tmp="$(mktemp -d)"
  local url
  url=$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" \
        | grep -oE '"browser_download_url":\s*"[^"]+"' \
        | cut -d'"' -f4 \
        | grep -Ei "$asset_pattern" \
        | head -n1 || true)
  if [[ -z "$url" ]]; then
    warn "Could not find a matching release asset for $name (pattern: $asset_pattern). Skipping — install manually."
    rm -rf "$tmp"; return
  fi
  curl -fsSL "$url" -o "$tmp/asset"
  case "$url" in
    *.tar.gz|*.tgz) tar -xzf "$tmp/asset" -C "$tmp" ;;
    *.zip) unzip -q "$tmp/asset" -d "$tmp" ;;
    *) cp "$tmp/asset" "$tmp/$binary_in_archive" ;;
  esac
  local found
  found=$(find "$tmp" -type f -name "$binary_in_archive" | head -n1)
  if [[ -z "$found" ]]; then
    warn "Downloaded $name but couldn't locate binary '$binary_in_archive' inside archive. Check $tmp manually."
    return
  fi
  install -m 755 "$found" "$BIN_DIR/$name"
  rm -rf "$tmp"
  ok "$name installed to $BIN_DIR/$name"
}

# ---------------------------------------------------------------------------
# 1. Base system packages
# ---------------------------------------------------------------------------
install_base_packages() {
  info "Updating dnf and installing base packages..."
  sudo dnf upgrade -y --refresh
  sudo dnf install -y \
    @development-tools curl wget git unzip zip tar gnupg2 \
    zsh vim tmux stow jq tree dnf-plugins-core \
    ripgrep fzf bat fd-find zoxide eza \
    p7zip p7zip-plugins unrar \
    fontconfig xclip wl-clipboard \
    python3 python3-pip pipx \
    fastfetch most \
    xdg-utils
  ok "Base packages installed"
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
  ok "zsh plugins ready (note: the repo's .zshrc sources /opt/homebrew paths for these — that's a macOS path. After stowing, edit .zshrc to source from \$ZSH/custom/plugins instead, or leave as-is and those two lines will just silently no-op on Linux)"
}

# ---------------------------------------------------------------------------
# 3. Neovim (latest stable release — needed for the built-in vim.pack
#    plugin manager used in this config; Fedora's repo version can lag behind)
# ---------------------------------------------------------------------------
install_neovim() {
  if has nvim && nvim --version | head -1 | grep -qE 'v0\.(1[2-9]|[2-9][0-9])'; then
    ok "Neovim already up to date"
    return
  fi
  info "Installing latest Neovim release..."
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
# 4. Modern CLI tools not reliably available/current in dnf
# ---------------------------------------------------------------------------
install_modern_cli() {
  if ! has starship; then
    info "Installing starship..."
    curl -fsSL https://starship.rs/install.sh | sh -s -- -y --bin-dir "$BIN_DIR"
  else ok "starship already installed"; fi

  gh_install "lazygit" "jesseduffield/lazygit" "Linux_x86_64\.tar\.gz" "lazygit"
  gh_install "delta"   "dandavison/delta" "x86_64-unknown-linux-gnu\.tar\.gz" "delta"
  gh_install "yazi"    "sxyazi/yazi" "x86_64-unknown-linux-gnu\.zip" "yazi"
  gh_install "zellij"  "zellij-org/zellij" "x86_64-unknown-linux-musl\.tar\.gz" "zellij"

  # fd-find installs the binary as 'fd' on Fedora already; eza/fastfetch/bat/zoxide come from dnf above
  ok "Modern CLI tools ready"
}

# ---------------------------------------------------------------------------
# 5. Terminal emulators + Zed
# ---------------------------------------------------------------------------
install_terminals() {
  info "Installing alacritty and kitty..."
  sudo dnf install -y alacritty kitty || warn "alacritty/kitty not found — install manually if needed"

  if ! has wezterm; then
    info "Installing WezTerm via COPR..."
    sudo dnf copr enable -y wezfurlong/wezterm-nightly || warn "Could not enable WezTerm COPR"
    sudo dnf install -y wezterm || warn "WezTerm install failed — see https://wezterm.org/installation.html"
  else ok "wezterm already installed"; fi

  if ! has ghostty; then
    info "Installing Ghostty via COPR..."
    sudo dnf copr enable -y pgdev/ghostty || warn "Could not enable Ghostty COPR — see https://ghostty.org/download"
    sudo dnf install -y ghostty || warn "Ghostty install failed — see https://ghostty.org/download"
  else ok "ghostty already installed"; fi

  if ! has zed; then
    info "Installing Zed editor..."
    curl -fsSL https://zed.dev/install.sh | sh
  else ok "zed already installed"; fi
}

# ---------------------------------------------------------------------------
# 6. tmux plugin manager
# ---------------------------------------------------------------------------
install_tpm() {
  local tpm_dir="$HOME/.config/tmux/.tmux/plugins/tpm"
  if [[ -d "$tpm_dir" ]]; then ok "TPM already installed"; return; fi
  info "Installing tmux plugin manager (TPM)..."
  git clone -q https://github.com/tmux-plugins/tpm "$tpm_dir"
  ok "TPM installed (open tmux and press prefix + I to install plugins)"
}

# ---------------------------------------------------------------------------
# 7. Nerd Font (JetBrains Mono — required by every terminal config in this repo)
# ---------------------------------------------------------------------------
install_nerd_font() {
  local font_dir="$HOME/.local/share/fonts"
  if fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd Font"; then
    ok "JetBrainsMono Nerd Font already installed"; return
  fi
  info "Installing JetBrainsMono Nerd Font..."
  mkdir -p "$font_dir"
  local tmp; tmp="$(mktemp -d)"
  curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" -o "$tmp/font.zip"
  unzip -q "$tmp/font.zip" -d "$font_dir"
  rm -rf "$tmp"
  fc-cache -f "$font_dir" >/dev/null 2>&1
  ok "Font installed"
}

# ---------------------------------------------------------------------------
# 8. Optional dev tooling used by the .zshrc aliases (docker, go, rust, bun, kubectl)
# ---------------------------------------------------------------------------
install_dev_tools() {
  if ! has node; then
    info "Installing Node.js..."
    sudo dnf install -y nodejs npm
  else ok "node already installed"; fi

  if ! has go; then
    info "Installing Go..."
    sudo dnf install -y golang
  else ok "go already installed"; fi

  if ! has cargo; then
    info "Installing Rust (rustup)..."
    curl -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path
    echo '. "$HOME/.cargo/env"' >> "$HOME/.profile"
  else ok "cargo already installed"; fi

  if ! has bun; then
    info "Installing Bun..."
    curl -fsSL https://bun.sh/install | bash
  else ok "bun already installed"; fi

  if ! has docker; then
    info "Installing Docker..."
    sudo dnf install -y dnf-plugins-core
    sudo dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo systemctl enable --now docker
    sudo usermod -aG docker "$USER"
    warn "Log out/in (or run 'newgrp docker') for the docker group change to take effect"
  else ok "docker already installed"; fi

  if ! has kubectl; then
    info "Installing kubectl..."
    curl -fsSL "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/${GH_ARCH/x86_64/amd64}/kubectl" -o "$BIN_DIR/kubectl"
    chmod +x "$BIN_DIR/kubectl"
  else ok "kubectl already installed"; fi
}

# ---------------------------------------------------------------------------
# 9. Clone dotfiles and symlink with GNU stow
# ---------------------------------------------------------------------------
setup_dotfiles() {
  if [[ -d "$DOTFILES_DIR" ]]; then
    info "Dotfiles repo already present at $DOTFILES_DIR, pulling latest..."
    git -C "$DOTFILES_DIR" pull --ff-only
  else
    info "Cloning dotfiles repo..."
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  fi
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
  install_base_packages
  install_zsh
  install_neovim
  install_vim_plug
  install_modern_cli
  install_terminals
  install_tpm
  install_nerd_font
  $WITH_DEV_TOOLS && install_dev_tools || warn "Skipping dev tools (--no-dev)"
  $WITH_STOW && setup_dotfiles || warn "Skipping dotfiles stow (--no-stow)"
  set_default_shell

  echo
  ok "All done!"
  echo "Next steps:"
  echo "  1. Log out/in (or reboot) so the zsh/docker group changes apply."
  echo "  2. Set your terminal font to 'JetBrainsMono Nerd Font'."
  echo "  3. Open tmux and press: Ctrl-A then I   -> installs tmux plugins (TPM)."
  echo "  4. Open nvim and run: :PackUpdate       -> installs Neovim plugins."
  echo "  5. Open vim and run: :PlugInstall       -> installs classic-vim plugins."
  echo "  6. If the Ghostty/WezTerm COPR steps failed, check the current repo names at"
  echo "     https://ghostty.org/download and https://wezterm.org/installation.html"
}

main "$@"
