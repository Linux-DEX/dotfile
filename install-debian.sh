#!/usr/bin/env bash
#
# install-debian.sh
# Sets up a Debian / Ubuntu machine to match https://github.com/Linux-DEX/dotfile
#
# Installs: zsh + oh-my-zsh, starship, neovim (latest), vim + vim-plug,
#           tmux + TPM, zellij, GNU stow, modern CLI (eza, bat, fd, ripgrep,
#           fzf, zoxide, lazygit, git-delta, yazi, fastfetch), terminal
#           emulators (alacritty, kitty, wezterm, ghostty*), Zed editor,
#           JetBrains Mono Nerd Font, and (optionally) docker/go/rust/bun/kubectl.
#           Finally clones the dotfiles repo and symlinks everything with stow.
#
# Usage:
#   chmod +x install-debian.sh
#   ./install-debian.sh              # full install
#   ./install-debian.sh --no-dev     # skip docker/go/rust/bun/kubectl
#   ./install-debian.sh --no-stow    # install tools only, don't touch dotfiles
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
  err "sudo is required but not found. Install sudo first (as root: apt install sudo)."
  exit 1
fi

# NOTE: this script targets Debian 12 (bookworm) / Ubuntu 22.04+ or newer —
# that's the baseline where bat/fd-find/ripgrep/zoxide/fastfetch exist in apt.
# On older releases, the "modern CLI" step below will fall back to GitHub
# releases automatically for anything apt doesn't have.
ARCH="$(uname -m)"
case "$ARCH" in
  # GH_ARCH:      used for target-triple style asset names (eza, delta, yazi, zellij)
  # LAZYGIT_ARCH: lazygit uses "x86_64"/"arm64" (not "aarch64")
  # FASTFETCH_ARCH: fastfetch uses "amd64"/"aarch64"
  # DL_ARCH:      "amd64"/"arm64" convention used by go.dev, kubernetes, docker, etc.
  x86_64)  GH_ARCH="x86_64";  NVIM_ARCH="linux-x86_64"; LAZYGIT_ARCH="x86_64"; FASTFETCH_ARCH="amd64";   DL_ARCH="amd64" ;;
  aarch64|arm64) GH_ARCH="aarch64"; NVIM_ARCH="linux-arm64"; LAZYGIT_ARCH="arm64"; FASTFETCH_ARCH="aarch64"; DL_ARCH="arm64" ;;
  *) err "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# ---------------------------------------------------------------------------
# Generic helper: download a binary/archive from the latest GitHub release
# and drop the extracted binary into $BIN_DIR. Used for tools that aren't
# reliably packaged (or are outdated) across Debian/Ubuntu versions.
# ---------------------------------------------------------------------------
gh_install() {
  local name="$1" repo="$2" asset_pattern="$3" binary_in_archive="$4"
  if has "$name"; then ok "$name already installed, skipping"; return; fi
  info "Installing $name from GitHub releases ($repo)..."
  local tmp; tmp="$(mktemp -d)"
  local api_response; api_response=$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" 2>/dev/null || true)
  if echo "$api_response" | grep -qi "rate limit exceeded"; then
    warn "GitHub API rate limit hit while installing $name. Wait ~an hour, or install manually from https://github.com/$repo/releases/latest — skipping for now."
    rm -rf "$tmp"; return
  fi
  local url
  url=$(echo "$api_response" \
        | grep -oE '"browser_download_url":\s*"[^"]+"' \
        | cut -d'"' -f4 \
        | grep -Ei "$asset_pattern" \
        | head -n1 || true)
  if [[ -z "$url" ]]; then
    warn "Could not find a matching release asset for $name (pattern: $asset_pattern). Skipping — install manually from https://github.com/$repo/releases/latest"
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
  info "Updating apt..."
  sudo apt update

  info "Installing core packages (safe on any Debian/Ubuntu release)..."
  sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    build-essential curl wget git unzip zip tar gnupg ca-certificates software-properties-common \
    zsh vim tmux stow jq tree \
    fontconfig xclip wl-clipboard \
    python3 python3-pip python3-venv pipx \
    xdg-utils apt-transport-https
  ok "Core packages installed"

  # These are newer packages that don't exist on every Debian/Ubuntu release.
  # Install one at a time so a single missing name can't abort the whole batch
  # (apt/dnf fail the *entire* transaction if any package in the list is unknown).
  info "Installing modern CLI packages (best-effort per package)..."
  local modern_pkgs=(ripgrep fzf bat fd-find zoxide p7zip-full unrar-free most)
  for pkg in "${modern_pkgs[@]}"; do
    sudo DEBIAN_FRONTEND=noninteractive apt install -y "$pkg" \
      && ok "$pkg installed" \
      || warn "$pkg not available in apt on this release — will try a fallback where possible"
  done

  # Debian/Ubuntu names some binaries differently — normalize with symlinks
  if has batcat && ! has bat; then ln -sf "$(command -v batcat)" "$BIN_DIR/bat"; fi
  if has fdfind && ! has fd; then ln -sf "$(command -v fdfind)" "$BIN_DIR/fd"; fi
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
# 3. Neovim (latest stable release — needed for the built-in vim.pack
#    plugin manager used in this config; distro repo versions are often too old)
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
# 4. Modern CLI tools not reliably available/current in apt
# ---------------------------------------------------------------------------
install_modern_cli() {
  if ! has starship; then
    info "Installing starship..."
    curl -fsSL https://starship.rs/install.sh | sh -s -- -y --bin-dir "$BIN_DIR"
  else ok "starship already installed"; fi

  if ! has zoxide; then
    curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
  else ok "zoxide already installed"; fi

  gh_install "eza"     "eza-community/eza"     "${GH_ARCH}-unknown-linux-gnu\.tar\.gz" "eza"
  gh_install "lazygit" "jesseduffield/lazygit"  "Linux_${LAZYGIT_ARCH}\.tar\.gz"        "lazygit"
  gh_install "delta"   "dandavison/delta"       "${GH_ARCH}-unknown-linux-gnu\.tar\.gz" "delta"
  gh_install "yazi"    "sxyazi/yazi"            "${GH_ARCH}-unknown-linux-gnu\.zip"     "yazi"
  gh_install "zellij"  "zellij-org/zellij"      "${GH_ARCH}-unknown-linux-musl\.tar\.gz" "zellij"
  gh_install "fastfetch" "fastfetch-cli/fastfetch" "linux-${FASTFETCH_ARCH}\.tar\.gz"   "fastfetch"

  # fd/ripgrep/zoxide/bat may not have installed via apt above (older releases) — catch those too
  if ! has fd; then gh_install "fd" "sharkdp/fd" "${GH_ARCH}-unknown-linux-gnu\.tar\.gz" "fd"; fi
  if ! has rg; then gh_install "rg" "BurntSushi/ripgrep" "${GH_ARCH}-unknown-linux-gnu\.tar\.gz" "rg"; fi
  if ! has bat; then gh_install "bat" "sharkdp/bat" "${GH_ARCH}-unknown-linux-gnu\.tar\.gz" "bat"; fi

  # .zshrc uses `eval "$(fzf --zsh)"`, which needs fzf >= 0.48 — Debian's apt fzf
  # can be as old as 0.38 (Bookworm), which would error on every shell start.
  local fzf_ver; fzf_ver=$(fzf --version 2>/dev/null | awk '{print $1}')
  if [[ -z "$fzf_ver" ]] || [[ "$(printf '%s\n%s\n' "0.48.0" "$fzf_ver" | sort -V | head -1)" != "0.48.0" ]]; then
    info "apt's fzf ($fzf_ver) is too old for --zsh support, installing a newer one into $BIN_DIR..."
    local tmp; tmp="$(mktemp -d)"
    local url; url=$(curl -fsSL "https://api.github.com/repos/junegunn/fzf/releases/latest" \
        | grep -oE '"browser_download_url":\s*"[^"]+"' | cut -d'"' -f4 \
        | grep -Ei "linux_${GH_ARCH}\.tar\.gz" | head -n1 || true)
    if [[ -n "$url" ]]; then
      curl -fsSL "$url" -o "$tmp/fzf.tar.gz" && tar -xzf "$tmp/fzf.tar.gz" -C "$tmp"
      install -m 755 "$tmp/fzf" "$BIN_DIR/fzf"
      ok "Newer fzf installed to $BIN_DIR/fzf (shadows apt's older one via PATH)"
    else
      warn "Could not fetch a newer fzf — remove 'eval \"\$(fzf --zsh)\"' from .zshrc or install fzf manually if it errors"
    fi
    rm -rf "$tmp"
  fi
}

# ---------------------------------------------------------------------------
# 5. Terminal emulators + Zed
# ---------------------------------------------------------------------------
install_terminals() {
  info "Installing alacritty and kitty..."
  sudo apt install -y alacritty kitty || warn "alacritty/kitty not found in apt on this release — install manually if needed"

  if ! has wezterm; then
    info "Adding WezTerm's official apt repo..."
    curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
    echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list
    sudo apt update && sudo apt install -y wezterm || warn "WezTerm install failed — see https://wezterm.org/installation.html"
  else ok "wezterm already installed"; fi

  warn "Ghostty has no official Debian/Ubuntu package. Skipping — build from source or use a distro package (see https://ghostty.org/download) if you want it."

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
# 8. Editor/shell runtimes — these are NOT optional even though they look like
#    "dev tools": .zshrc unconditionally runs `export PATH=$PATH:$(go env GOPATH)/bin`
#    with no existence check, so a missing `go` breaks every shell startup with a
#    visible error. Node is needed for half of Mason's ensure_installed LSP list
#    (ts_ls, html, cssls, tailwindcss, emmet_ls, eslint) to install successfully.
#    So these always run, regardless of --no-dev.
# ---------------------------------------------------------------------------
install_editor_runtimes() {
  info "Installing Node.js (LTS) — required by Mason for ts_ls/html/cssls/tailwindcss/emmet_ls/eslint..."
  if ! has node; then
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt install -y nodejs
  else ok "node already installed"; fi

  info "Installing Go — required because .zshrc unconditionally runs 'go env GOPATH'..."
  if ! has go; then
    local gover; gover=$(curl -fsSL https://go.dev/VERSION?m=text | head -1)
    curl -fsSL "https://go.dev/dl/${gover}.linux-${DL_ARCH}.tar.gz" -o /tmp/go.tar.gz
    sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf /tmp/go.tar.gz
    sudo ln -sf /usr/local/go/bin/go /usr/local/bin/go
    sudo ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt
    echo 'export PATH=$PATH:/usr/local/go/bin' >> "$HOME/.profile"
  else ok "go already installed"; fi
}

# ---------------------------------------------------------------------------
# 9. Optional dev tooling used only by .zshrc aliases (docker, kubectl) or
#    that fail gracefully if absent (rust, bun) — safe to skip with --no-dev
# ---------------------------------------------------------------------------
install_dev_tools() {
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
    curl -fsSL https://get.docker.com | sudo sh
    sudo usermod -aG docker "$USER"
    warn "Log out/in (or run 'newgrp docker') for the docker group change to take effect"
  else ok "docker already installed"; fi

  if ! has kubectl; then
    info "Installing kubectl..."
    curl -fsSL "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/${DL_ARCH}/kubectl" -o "$BIN_DIR/kubectl"
    chmod +x "$BIN_DIR/kubectl"
  else ok "kubectl already installed"; fi
}

# ---------------------------------------------------------------------------
# 10. Clone dotfiles and symlink with GNU stow
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
  local moved=false
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
  install_base_packages
  install_zsh
  install_neovim
  install_vim_plug
  install_modern_cli
  install_terminals
  install_tpm
  install_nerd_font
  install_editor_runtimes
  $WITH_DEV_TOOLS && install_dev_tools || warn "Skipping optional dev tools (--no-dev): rust, bun, docker, kubectl"
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
  echo "  6. Ghostty was skipped (no Debian/Ubuntu package) — see https://ghostty.org/download"
}

main "$@"
