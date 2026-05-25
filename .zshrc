export ZSH="/home/$USER/.oh-my-zsh"
# ZSH_THEME="random"
# ZSH_THEME="dracula"
ZSH_THEME="robbyrussell"

plugins=(git)

HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt share_history 
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_verify
setopt hist_ignore_all_dups

# completion using arrow keys (based on history)
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

if [ -f $ZSH/oh-my-zsh.sh ]; then
  source $ZSH/oh-my-zsh.sh
fi

####   ARCOLINUX SETTINGS   ####
export PAGER='most'

if [ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

setopt GLOB_DOTS
#share commands between terminal instances or not
# unsetopt SHARE_HISTORY
setopt SHARE_HISTORY

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

export HISTCONTROL=ignoreboth:erasedups

# Make nano the default editor

export EDITOR='nvim'
export VISUAL='nvim'

#PS1='[\u@\h \W]\$ '

if [ -d "$HOME/.bin" ] ;
  then PATH="$HOME/.bin:$PATH"
fi

if [ -d "$HOME/.local/bin" ] ;
  then PATH="$HOME/.local/bin:$PATH"
fi

### ALIASES ###

#list
# alias ls='ls --color=auto'
alias ls='eza --icons=always --no-time --long --git --no-filesize --no-user --no-permissions'
alias la='eza -a --icons --color=always --group-directories-first'
alias ll='eza -lah'
alias lg='lazygit'
alias l='eza --icons --grid --classify --colour=auto --sort=type --group-directories-first --header --modified --created --git --binary --group'
alias l.="ls -A | egrep '^\.'"
alias listdir="ls -d */ > list"

# show the list of packages that need this package - depends mpv as example
function_depends()  {
    search=$(echo "$1")
    sudo pacman -Sii $search | grep "Required" | sed -e "s/Required By     : //g" | sed -e "s/  /\n/g"
    }

alias depends='function_depends'

#fix obvious typo's
alias cd..='cd ..'
alias pdw='pwd'

## Colorize the grep command output for ease of use (good for log files)##
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

#readable output
alias df='df -h'

#free
alias free="free -mt"

#continue download
alias wget="wget -c"

#userlist
alias userlist="cut -d: -f1 /etc/passwd | sort"

#merge new settings
alias merge="xrdb -merge ~/.Xresources"

#ps
alias psa="ps auxf"
alias psgrep="ps aux | grep -v grep | grep -i -e VSZ -e"

#grub update
alias update-grub="sudo grub-mkconfig -o /boot/grub/grub.cfg"
alias grub-update="sudo grub-mkconfig -o /boot/grub/grub.cfg"
#grub issue 08/2022
alias install-grub-efi="sudo grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ArcoLinux"

#add new fonts
alias update-fc='sudo fc-cache -fv'

#copy/paste all content of /etc/skel over to home folder - backup of config created - beware
#skel alias has been replaced with a script at /usr/local/bin/skel

#backup contents of /etc/skel to hidden backup folder in home/user
alias bupskel='cp -Rf /etc/skel ~/.skel-backup-$(date +%Y.%m.%d-%H.%M.%S)'

#copy shell configs
alias cb='cp /etc/skel/.bashrc ~/.bashrc && echo "Copied."'
alias cz='cp /etc/skel/.zshrc ~/.zshrc && exec zsh'
alias cf='cp /etc/skel/.config/fish/config.fish ~/.config/fish/config.fish && echo "Copied."'

#switch between bash and zsh
alias tobash="sudo chsh $USER -s /bin/bash && echo 'Now log out.'"
alias tozsh="sudo chsh $USER -s /bin/zsh && echo 'Now log out.'"
alias tofish="sudo chsh $USER -s /bin/fish && echo 'Now log out.'"

#hardware info --short
alias hw="hwinfo --short"

#audio check pulseaudio or pipewire
alias audio="pactl info | grep 'Server Name'"

#skip integrity check
alias paruskip='paru -S --mflags --skipinteg'
alias yayskip='yay -S --mflags --skipinteg'
alias trizenskip='trizen -S --skipinteg'

#check vulnerabilities microcode
alias microcode='grep . /sys/devices/system/cpu/vulnerabilities/*'

#clear
alias clean="clear; seq 1 $(tput cols) | sort -R | sparklines | lolcat"
alias c="clear"

#search content with ripgrep
alias rg="rg --sort path"

#get the error messages from journalctl
alias jctl="journalctl -p 3 -xb"

#nano for important configuration files
#know what you do in these files
alias nlxdm="sudo $EDITOR /etc/lxdm/lxdm.conf"
alias nlightdm="sudo $EDITOR /etc/lightdm/lightdm.conf"
alias npacman="sudo $EDITOR /etc/pacman.conf"
alias ngrub="sudo $EDITOR /etc/default/grub"
alias nconfgrub="sudo $EDITOR /boot/grub/grub.cfg"
alias nmkinitcpio="sudo $EDITOR /etc/mkinitcpio.conf"
alias nmirrorlist="sudo $EDITOR /etc/pacman.d/mirrorlist"
alias narcomirrorlist="sudo $EDITOR /etc/pacman.d/arcolinux-mirrorlist"
alias nsddm="sudo $EDITOR /etc/sddm.conf"
alias nsddmk="sudo $EDITOR /etc/sddm.conf.d/kde_settings.conf"
alias nfstab="sudo $EDITOR /etc/fstab"
alias nnsswitch="sudo $EDITOR /etc/nsswitch.conf"
alias nsamba="sudo $EDITOR /etc/samba/smb.conf"
alias ngnupgconf="sudo $EDITOR /etc/pacman.d/gnupg/gpg.conf"
alias nhosts="sudo $EDITOR /etc/hosts"
alias nhostname="sudo $EDITOR /etc/hostname"
alias nresolv="sudo $EDITOR /etc/resolv.conf"
alias nb="$EDITOR ~/.bashrc"
alias nz="$EDITOR ~/.zshrc"
alias nf="$EDITOR ~/.config/fish/config.fish"
alias nneofetch="$EDITOR ~/.config/neofetch/config.conf"
alias nplymouth="sudo $EDITOR /etc/plymouth/plymouthd.conf"
alias nvconsole="sudo $EDITOR /etc/vconsole.conf"
alias nenvironment="sudo $EDITOR /etc/environment"

#reading logs with bat
alias lcalamares="bat /var/log/Calamares.log"
alias lpacman="bat /var/log/pacman.log"
alias lxorg="bat /var/log/Xorg.0.log"
alias lxorgo="bat /var/log/Xorg.0.log.old"

#gpg
#verify signature for isos
alias gpg-check="gpg2 --keyserver-options auto-key-retrieve --verify"
alias fix-gpg-check="gpg2 --keyserver-options auto-key-retrieve --verify"
#receive the key of a developer
alias gpg-retrieve="gpg2 --keyserver-options auto-key-retrieve --receive-keys"
alias fix-gpg-retrieve="gpg2 --keyserver-options auto-key-retrieve --receive-keys"
alias fix-keyserver="[ -d ~/.gnupg ] || mkdir ~/.gnupg ; cp /etc/pacman.d/gnupg/gpg.conf ~/.gnupg/ ; echo 'done'"

#fixes
alias fix-permissions="sudo chown -R $USER:$USER ~/.config ~/.local"
alias keyfix="/usr/local/bin/arcolinux-fix-pacman-databases-and-keys"
alias key-fix="/usr/local/bin/arcolinux-fix-pacman-databases-and-keys"
alias keys-fix="/usr/local/bin/arcolinux-fix-pacman-databases-and-keys"
alias fixkey="/usr/local/bin/arcolinux-fix-pacman-databases-and-keys"
alias fixkeys="/usr/local/bin/arcolinux-fix-pacman-databases-and-keys"
alias fix-key="/usr/local/bin/arcolinux-fix-pacman-databases-and-keys"
alias fix-keys="/usr/local/bin/arcolinux-fix-pacman-databases-and-keys"
#fix-sddm-config is no longer an alias but an application - part of ATT
#alias fix-sddm-config="/usr/local/bin/arcolinux-fix-sddm-config"
alias fix-pacman-conf="/usr/local/bin/arcolinux-fix-pacman-conf"
alias fix-pacman-keyserver="/usr/local/bin/arcolinux-fix-pacman-gpg-conf"
alias fix-grub="/usr/local/bin/arcolinux-fix-grub"
alias fixgrub="/usr/local/bin/arcolinux-fix-grub"

#maintenance
alias big="expac -H M '%m\t%n' | sort -h | nl"
alias downgrada="sudo downgrade --ala-url https://ant.seedhost.eu/arcolinux/"

#hblock (stop tracking with hblock)
#use unhblock to stop using hblock
alias unhblock="hblock -S none -D none"

#systeminfo
alias probe="sudo -E hw-probe -all -upload"
alias sysfailed="systemctl list-units --failed"

#shutdown or reboot
alias ssn="shutdown now"
alias sr="reboot"

#update betterlockscreen images
alias bls="betterlockscreen -u /usr/share/backgrounds/arcolinux/"

#give the list of all installed desktops - xsessions desktops
alias xd="ls /usr/share/xsessions"
alias xdw="ls /usr/share/wayland-sessions"

# # ex = EXtractor for all kinds of archives
# # usage: ex <file>
ex ()
{
  if [ -f $1 ] ; then
    case $1 in
      *.tar.bz2)   tar xjf $1   ;;
      *.tar.gz)    tar xzf $1   ;;
      *.bz2)       bunzip2 $1   ;;
      *.rar)       unrar x $1   ;;
      *.gz)        gunzip $1    ;;
      *.tar)       tar xf $1    ;;
      *.tbz2)      tar xjf $1   ;;
      *.tgz)       tar xzf $1   ;;
      *.zip)       unzip $1     ;;
      *.Z)         uncompress $1;;
      *.7z)        7z x $1      ;;
      *.deb)       ar x $1      ;;
      *.tar.xz)    tar xf $1    ;;
      *.tar.zst)   tar xf $1    ;;
      *)           echo "'$1' cannot be extracted via ex()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

#wayland aliases
alias wsimplescreen="wf-recorder -a"
alias wsimplescreenrecorder="wf-recorder -a -c h264_vaapi -C aac -d /dev/dri/renderD128 --file=recording.mp4"

#btrfs aliases
alias btrfsfs="sudo btrfs filesystem df /"
alias btrfsli="sudo btrfs su li / -t"

#snapper aliases
alias snapcroot="sudo snapper -c root create-config /"
alias snapchome="sudo snapper -c home create-config /home"
alias snapli="sudo snapper list"
alias snapcr="sudo snapper -c root create"
alias snapch="sudo snapper -c home create"

#Leftwm aliases
alias lti="leftwm-theme install"
alias ltu="leftwm-theme uninstall"
alias lta="leftwm-theme apply"
alias ltupd="leftwm-theme update"
alias ltupg="leftwm-theme upgrade"

#git
alias rmgitcache="rm -r ~/.cache/git"
alias grh="git reset --hard"

#pamac
alias pamac-unlock="sudo rm /var/tmp/pamac/dbs/db.lock"

#moving your personal files and folders from /personal to ~
alias personal='cp -Rf /personal/* ~'

#create a file called .zshrc-personal and put all your personal aliases
#in there. They will not be overwritten by skel.

[[ -f ~/.zshrc-personal ]] && . ~/.zshrc-personal

eval "$(starship init zsh)"

# export PATH="$PATH:/home/xander/.flutter/flutter/bin"

# CHROME_EXECUTABLE=/usr/bin/chromium
# export CHROME_EXECUTABLE

export LC_CTYPE="en_GB.utf8"
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# export ANDROID_HOME=/home/xander/Android/Sdk

# Use this for load application on nvidia
export __NV_PRIME_RENDER_OFFLOAD=1
# __GLX_VENDOR_LIBRARY_NAME=nvidia %command%

# export ANDROID_HOME=~/Android/Sdk
# export PATH=$PATH:$ANDROID_HOME/emulator

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

set -o emacs

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:~/.local/lib/mojo
export PATH=$PATH:~/.modular/pkg/packages.modular.com_mojo/bin/

# setup fzf key binding
eval "$(fzf --zsh)"


export PATH=$HOME/.local/bin:$PATH

# auto suggestion 
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# zsh syntax
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# -- Use fd instead of fzf --

# ctrl + R for history search 
# ctrl + T for file and directory search
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

# Use fd (https://github.com/sharkdp/fd) for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1"
}

# in home directory clone https://github.com/junegunn/fzf-git.sh.git
# key-binding ctrl + G + H
source ~/fzf-git.sh/fzf-git.sh

show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi"

export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

# Advanced customization of fzf options via _fzf_comprun function
# - The first argument to the function is the name of the command.
# - You should make sure to pass the rest of the arguments to fzf.
_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo \${}'"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    *)            fzf --preview "$show_file_or_dir_preview" "$@" ;;
  esac
}

# --- Bat (better cat ) ---

export BAT_THEME=Dracula

# --- Zoxide (better cd) ---
eval "$(zoxide init zsh)"

alias cd="z"

# Enable case-insensitive globbing
setopt NO_CASE_GLOB

# Make completion case-insensitive
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# cargo rush path
export PATH="$HOME/.cargo/bin:$PATH"

# --- yazi setup ---
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# --- running cpp code ---
# alias runcpp='f() { g++ -std=c++17 -o "${1%.}" "$1" && ./"${1%.}"; }; f'
runcpp() {
  if [ -z "$1" ]; then
    echo "Usage: runcpp <filename.cpp>"
    return 1
  fi

  if [[ ! "$1" =~ \.cpp$ ]]; then
    echo "Error: File must have a .cpp extension."
    return 1
  fi

  local output_name="${1%.*}"
  g++ -std=c++17 -Wall -Wextra -o "$output_name" "$1" && ./"$output_name"
}

# uv suggestion 
# eval "$(uv generate-shell-completion zsh)"
# export UV_LINK_MODE=copy

export GHOSTTY_RENDERER=gpu

# bun completions
[ -s "/Users/sarabjeet.9353gmail.com/.bun/_bun" ] && source "/Users/sarabjeet.9353gmail.com/.bun/_bun"

# autoload -U compinit
# compinit
# # uv suggestion 
# eval "$(uv generate-shell-completion zsh)"


# chpwd ls hook
function chpwd_ls() {
  l
}

# chpwd hook for python
function chpwd_venv() {
  if [[ -d .venv ]]; then 
    source .venv/bin/activate
  elif [[ -d venv ]]; then
    source venv/bin/activate
  elif [[ -n "$VIRTUAL_ENV" ]]; then
    deactivate
  fi
}

autoload -U add-zsh-hook
add-zsh-hook chpwd chpwd_ls
# add-zsh-hook chpwd chpwd_venv


# Open the current command in your $EDITOR (e.g., neovim)
# Press Ctrl+X followed by Ctrl+E to trigger
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line


# Expands history expressions like !! or !$ when you press space
bindkey ' ' magic-space

# golang path for gopls package
export PATH=$PATH:$(go env GOPATH)/bin

# kubectl alias
# Main alias
alias k='kubectl'

# Get resources
alias kg='kubectl get'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgd='kubectl get deployments'
alias kgn='kubectl get nodes'
alias kga='kubectl get all'
alias kgns='kubectl get namespaces'

# Describe resources
alias kd='kubectl describe'
alias kdp='kubectl describe pod'
alias kdd='kubectl describe deployment'

# Logs
alias kl='kubectl logs'
alias klf='kubectl logs -f'

# Execute into pod
alias ke='kubectl exec -it'
alias ksh='kubectl exec -it -- /bin/sh'
alias kbash='kubectl exec -it -- /bin/bash'

# Apply/Delete
alias ka='kubectl apply -f'
alias kaf='kubectl apply -f'
alias kdelf='kubectl delete -f'
alias kdel='kubectl delete'

# Namespace
alias kctx='kubectl config current-context'
alias kuse='kubectl config use-context'
alias kns='kubectl config set-context --current --namespace'

# Watch resources
alias kgpw='kubectl get pods -w'
alias kgaw='kubectl get all -w'

# Port forwarding
alias kpf='kubectl port-forward'

# Restart deployment
alias kroll='kubectl rollout restart deployment'

# Scale deployment
alias kscale='kubectl scale deployment'

# Top (metrics-server required)
alias ktop='kubectl top'
alias ktopp='kubectl top pod'
alias ktopn='kubectl top node'

# Contexts
alias kcx='kubectl config get-contexts'

# Events
alias kev='kubectl get events --sort-by=.metadata.creationTimestamp'

# Edit resources
alias kedit='kubectl edit'

# Explain resources
alias kexp='kubectl explain'

# replicaset
alias kgr='kubectl get replicasets.'

# Docker alias
alias d='docker'
alias dc='docker compose'

# Containers
alias dps='docker ps'
alias dpsa='docker ps -a'
alias dex='docker exec -it'
alias dstop='docker stop'
alias dstart='docker start'
alias drestart='docker restart'
alias drm='docker rm'
alias dkill='docker kill'

# Images
alias di='docker images'
alias drmi='docker rmi'
alias dbuild='docker build'
alias dpull='docker pull'
alias dpush='docker push'

# Logs
alias dlog='docker logs'
alias dlogf='docker logs -f'

# Run / inspect
alias drun='docker run'
alias dins='docker inspect'
alias dstat='docker stats'

# Cleanup
alias dprune='docker system prune -f'
alias dclean='docker system prune -a --volumes -f'
alias dcc='docker container prune -f'
alias dic='docker image prune -f'
alias dvc='docker volume prune -f'
alias dnc='docker network prune -f'

# Compose
alias dcup='docker compose up'
alias dcupd='docker compose up -d'
alias dcdown='docker compose down'
alias dcps='docker compose ps'
alias dclogs='docker compose logs'
alias dclogf='docker compose logs -f'
alias dcexec='docker compose exec'
alias dcb='docker compose build'
alias dcrestart='docker compose restart'

# Quick shell into first running container
alias dbash='docker exec -it $(docker ps -q | head -1) bash'
alias dsh='docker exec -it $(docker ps -q | head -1) sh'

# Shortcuts
alias g='git'
alias gs='git status'
alias ga='git add'
alias gaa='git add .'
alias gc='git commit -m'
alias gca='git commit --amend'
alias gcam='git commit -am'

# Push / Pull
alias gp='git push'
alias gpl='git pull'
alias gpf='git push --force-with-lease'
alias gpo='git push origin'
alias gplo='git pull origin'

# Branches
alias gb='git branch'
alias gba='git branch -a'
alias gbd='git branch -d'
alias gbD='git branch -D'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gsw='git switch'
alias gswc='git switch -c'

# Merge / Rebase
alias gm='git merge'
alias gr='git rebase'
alias gra='git rebase --abort'
alias grc='git rebase --continue'
alias grq='git rebase --quit'

# Logs
alias gl='git log --oneline'
alias gla='git log --oneline --all --graph --decorate'
alias glg='git log --graph --oneline --decorate --all'

# Diff
alias gd='git diff'
alias gds='git diff --staged'

# Stash
alias gst='git stash'
alias gstp='git stash pop'
alias gstl='git stash list'

# Fetch
alias gf='git fetch'
alias gfa='git fetch --all'

# Reset
alias grh='git reset --hard'
alias grs='git reset --soft HEAD~1'

# Restore
alias gres='git restore'
alias gress='git restore --staged'

# Tags
alias gt='git tag'

# Cherry-pick
alias gcp='git cherry-pick'

# Show remote
alias grv='git remote -v'

# Current branch
alias gbr='git branch --show-current'

# Undo last commit (keep changes)
alias guncommit='git reset --soft HEAD~1'

# Clean untracked files
alias gclean='git clean -fd'

# Pretty status
alias gsts='git status -sb'

# Quick commit: gcom "message"
gcom() {
  git add .
  git commit -m "$1"
}

# Push current branch
gpush() {
  git push origin $(git branch --show-current)
}

# Pull current branch
gpull() {
  git pull origin $(git branch --show-current)
}

# Create and switch branch
gnew() {
  git checkout -b "$1"
}
