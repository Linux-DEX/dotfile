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
  # GH_ARCH:      used for target-triple style asset names (delta, yazi, zellij)
  # LAZYGIT_ARCH: lazygit uses "x86_64"/"arm64" (not "aarch64")
  # DL_ARCH:      "amd64"/"arm64" convention used by kubernetes, docker, etc.
  x86_64)  GH_ARCH="x86_64";  NVIM_ARCH="linux-x86_64"; LAZYGIT_ARCH="x86_64"; FASTFETCH_ARCH="amd64";   DL_ARCH="amd64" ;;
  aarch64|arm64) GH_ARCH="aarch64"; NVIM_ARCH="linux-arm64"; LAZYGIT_ARCH="arm64"; FASTFETCH_ARCH="aarch64"; DL_ARCH="arm64" ;;
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
  info "Updating dnf..."
  sudo dnf upgrade -y --refresh

  info "Installing core packages..."
  sudo dnf install -y \
    @development-tools curl wget git unzip zip tar gnupg2 \
    zsh vim tmux stow jq tree dnf-plugins-core \
    fontconfig xclip wl-clipboard \
    python3 python3-pip pipx \
    xdg-utils
  ok "Core packages installed"

  # RPM Fusion — needed for a full-featured (non-wrapper) unrar; harmless/idempotent otherwise
  if ! rpm -q rpmfusion-free-release >/dev/null 2>&1; then
    info "Enabling RPM Fusion (free) for full unrar support..."
    sudo dnf install -y "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
      || warn "Could not enable RPM Fusion — unrar will fall back to the limited open-source wrapper"
  fi

  # Install one at a time: dnf aborts the *entire* transaction if any single
  # package name doesn't exist on this Fedora release (eza has intermittently
  # dropped out of the repos — see: bugzilla.redhat.com/show_bug.cgi?id=2413750)
  info "Installing modern CLI packages (best-effort per package)..."
  local modern_pkgs=(ripgrep fzf bat fd-find zoxide p7zip p7zip-plugins unrar fastfetch most)
  for pkg in "${modern_pkgs[@]}"; do
    sudo dnf install -y "$pkg" \
      && ok "$pkg installed" \
      || warn "$pkg not available in dnf on this release — will try a fallback where possible"
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

  gh_install "lazygit" "jesseduffield/lazygit" "Linux_${LAZYGIT_ARCH}\.tar\.gz" "lazygit"
  gh_install "delta"   "dandavison/delta"      "${GH_ARCH}-unknown-linux-gnu\.tar\.gz" "delta"
  gh_install "yazi"    "sxyazi/yazi"           "${GH_ARCH}-unknown-linux-gnu\.zip" "yazi"
  gh_install "zellij"  "zellij-org/zellij"     "${GH_ARCH}-unknown-linux-musl\.tar\.gz" "zellij"

  # eza has intermittently disappeared from Fedora's repos (orphaned rust-eza package
  # on Fedora 42) — try dnf first since it's official when present, else fall back
  if ! has eza; then
    sudo dnf install -y eza \
      || gh_install "eza" "eza-community/eza" "${GH_ARCH}-unknown-linux-gnu\.tar\.gz" "eza"
  else ok "eza already installed"; fi

  # Catch anything the per-package dnf loop in install_base_packages missed
  if ! has fd; then gh_install "fd" "sharkdp/fd" "${GH_ARCH}-unknown-linux-gnu\.tar\.gz" "fd"; fi
  if ! has rg; then gh_install "rg" "BurntSushi/ripgrep" "${GH_ARCH}-unknown-linux-gnu\.tar\.gz" "rg"; fi
  if ! has bat; then gh_install "bat" "sharkdp/bat" "${GH_ARCH}-unknown-linux-gnu\.tar\.gz" "bat"; fi
  if ! has zoxide; then curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash; fi
  if ! has fastfetch; then gh_install "fastfetch" "fastfetch-cli/fastfetch" "linux-${FASTFETCH_ARCH}\.tar\.gz" "fastfetch"; fi

  # .zshrc uses `eval "$(fzf --zsh)"`, which needs fzf >= 0.48 — defensive check
  # in case an older Fedora release's fzf predates that flag.
  local fzf_ver; fzf_ver=$(fzf --version 2>/dev/null | awk '{print $1}')
  if [[ -z "$fzf_ver" ]] || [[ "$(printf '%s\n%s\n' "0.48.0" "$fzf_ver" | sort -V | head -1)" != "0.48.0" ]]; then
    info "Installed fzf ($fzf_ver) is too old for --zsh support, installing a newer one into $BIN_DIR..."
    local tmp; tmp="$(mktemp -d)"
    local url; url=$(curl -fsSL "https://api.github.com/repos/junegunn/fzf/releases/latest" \
        | grep -oE '"browser_download_url":\s*"[^"]+"' | cut -d'"' -f4 \
        | grep -Ei "linux_${GH_ARCH}\.tar\.gz" | head -n1 || true)
    if [[ -n "$url" ]]; then
      curl -fsSL "$url" -o "$tmp/fzf.tar.gz" && tar -xzf "$tmp/fzf.tar.gz" -C "$tmp"
      install -m 755 "$tmp/fzf" "$BIN_DIR/fzf"
      ok "Newer fzf installed to $BIN_DIR/fzf (shadows the older one via PATH)"
    else
      warn "Could not fetch a newer fzf — remove 'eval \"\$(fzf --zsh)\"' from .zshrc or install fzf manually if it errors"
    fi
    rm -rf "$tmp"
  fi
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
    sudo dnf install -y --refresh wezterm
    if ! has wezterm; then
      # Known issue on some Fedora releases: the "wezterm" virtual package installs
      # nothing — installing the real component packages directly works instead.
      warn "wezterm meta-package didn't produce a binary, trying component packages..."
      sudo dnf install -y --refresh wezterm-common wezterm-mux-server \
        || warn "WezTerm install failed — see https://wezterm.org/installation.html"
    fi
  else ok "wezterm already installed"; fi

  if ! has ghostty; then
    info "Installing Ghostty via COPR..."
    sudo dnf copr enable -y scottames/ghostty || warn "Could not enable Ghostty COPR — see https://ghostty.org/download"
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
# 8. Editor/shell runtimes — NOT optional even though they look like "dev tools":
#    .zshrc unconditionally runs `export PATH=$PATH:$(go env GOPATH)/bin` with no
#    existence check, so a missing `go` breaks every shell startup with a visible
#    error. Node is needed for half of Mason's ensure_installed LSP list (ts_ls,
#    html, cssls, tailwindcss, emmet_ls, eslint) to install successfully.
#    So these always run, regardless of --no-dev.
# ---------------------------------------------------------------------------
install_editor_runtimes() {
  if ! has node; then
    info "Installing Node.js — required by Mason for ts_ls/html/cssls/tailwindcss/emmet_ls/eslint..."
    sudo dnf install -y nodejs npm
  else ok "node already installed"; fi

  if ! has go; then
    info "Installing Go — required because .zshrc unconditionally runs 'go env GOPATH'..."
    sudo dnf install -y golang
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
    sudo dnf install -y dnf-plugins-core
    sudo dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo systemctl enable --now docker
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
# 9. Clone dotfiles and symlink with GNU stow
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
  echo "  6. If the Ghostty/WezTerm COPR steps failed, check the current repo names at"
  echo "     https://ghostty.org/download and https://wezterm.org/installation.html"
}

main "$@"
