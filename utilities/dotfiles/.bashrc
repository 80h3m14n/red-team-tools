# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# Better history behavior:Prevent duplicate spam, Preserve history across sessions, Cleaner command recall
HISTSIZE=1000
HISTFILESIZE=2000
HISTCONTROL=ignoreboth:erasedups
shopt -s histappend

# Case-insensitive globbing
shopt -s nocaseglob

# Fix small typos in cd
shopt -s cdspell

# Auto cd (type folder name directly)
# shopt -s autocd

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc
. "$HOME/.cargo/env"


# Gradle
export PATH=$PATH:/opt/gradle/bin

# Rust cargo
source $HOME/.cargo/env

# Golang compiled binaries
export PATH="$HOME/go/bin:$PATH"

# Mise version manager for node, python, golang, cmake and more
eval "$(~/.local/bin/mise activate bash)" 

# Prevent python bytecode creation
export PYTHONDONTWRITEBYTECODE=1

# Nim
export PATH=$HOME/.nimble/bin:$PATH

# GPG agent fix
export GPG_TTY=$(tty)
gpg-connect-agent updatestartuptty /bye >/dev/null

# Starship custom shell prompt
eval "$(starship init bash)"

# Metasploit
export PATH=$PATH:/opt/metasploit-framework/bin

# Set up fzf key bindings and fuzzy completion
eval "$(fzf --bash)"


# desc: Reverse DNS lookup via THC’s public IP tool 
rdns() {
    curl -m10 -fsSL "https://ip.thc.org/${1:?}?limit=20&f=${2}"
}

# Prepend shims to PATH - Hijacks Python-related stuff (tools installed via pip/pyenv) 
# Tell's the system to cheeck ~/.pyenv/shims  before /usr/bin
export PATH="$HOME/.pyenv/shims:$PATH"  


# zoxide: Instant directory jumping
# Usage: z dir-name 
eval "$(zoxide init bash)"

# desc: Lists all open ports with visibility (Public/Private/Loopback)
function ports() {
    sudo ss -tulnp | awk '
    BEGIN {
        print "\033[1;36mProto\tState\tPort\t\tVisibility\tAddress\t\tProcess\033[0m"
    }
    NR>1 {
        split($5,a,":")
        port=a[length(a)]
        addr=a[1]
        gsub(/users:\(\("?/,"",$7)
        gsub(/\)\)/,"",$7)

        # determine color and visibility
        if (addr == "127.0.0.1" || addr == "::1") {
            color="\033[1;31m"; vis="Loopback"
        } else if (addr == "0.0.0.0" || addr == "::" || addr == "*") {
            color="\033[1;32m"; vis="Public"
        } else {
            color="\033[1;33m"; vis="Private"
        }

        printf "%s%-5s\033[0m\t%-7s\t%-8s\t%-10s\t%-15s\t%s\n", color, $1, $2, port, vis, addr, $7
    }'
}

# SSH host autocomplete from ~/.ssh/config
_ssh_completion() {
  local SSH_FILES=()
  for f in "$HOME/.ssh/config" "$HOME/.ssh/config.local"; do
    [ -e "$f" ] && SSH_FILES+=("$f")
  done

  if [ "${#SSH_FILES[@]}" -ne 0 ]; then
    complete -o default -o nospace \
      -W "$(awk '/^Host\s+/{ print $2 }' "${SSH_FILES[@]}")" \
      ssh scp sftp
  fi
}
_ssh_completion
unset _ssh_completion


# desc: Search inside files with preview (rg + fzf)
rgi() {
  rg --line-number --color=always --smart-case "${1:-}" |
    fzf --ansi \
        --preview 'bat --style=numbers --color=always {1} --line-range {2}:+20' \
        --delimiter ':' \
        --nth 3..
}

# desc: Mini terminal help menu
function helpme() {
    echo -e "\n\033[1;36m🧩  Custom Commands, Functions, and Aliases Loaded in This Shell:\033[0m\n"

    # === Aliases ===
    echo -e "\033[1;33mAliases:\033[0m"
    awk '
        /^alias / {
            aliasName=$2
            sub(/=.*/,"",aliasName)
            print aliasName
        }
    ' ~/.bashrc | while read -r a; do
        desc=$(awk -v alias="$a" '
            $0 ~ "alias "alias"=" {
                if (NR>1 && prev ~ /^# desc:/) {sub(/^# desc:[[:space:]]*/, "", prev); print prev; exit}
            }
            {prev=$0}
        ' ~/.bashrc)
        [ -z "$desc" ] && desc="(no description)"
        echo -e "  \033[1;32m$a\033[0m  -  $desc"
    done
    echo ""

    # === Functions ===
    echo -e "\033[1;33mFunctions:\033[0m"
    declare -F | awk '{print $3}' | while read -r func; do
        desc=$(awk -v fn="$func" '
            $0 ~ "(function[[:space:]]+"fn"\\(\\)|^"fn"\\(\\))" {
                if (NR>1 && prev ~ /^# desc:/) {sub(/^# desc:[[:space:]]*/, "", prev); print prev; exit}
            }
            {prev=$0}
        ' ~/.bashrc)
        [ -z "$desc" ] && desc="(no description)"
        echo -e "  \033[1;35m$func\033[0m  -  $desc"
    done
    echo ""

    echo -e "\033[1;34mUsage:\033[0m"
    echo -e "  Type the alias or function name directly to use it."
    echo -e "  Example: \033[1;32mports\033[0m  → Show open ports with visibility."
    echo -e "  Example: \033[1;32mrdns 8.8.8.8\033[0m  → Reverse DNS lookup."
    echo -e "  Pipe with other commands: \033[1;32mports | grep "Public"\033[0m \n "

    echo -e "\033[1;90mHint:\033[0m Add '# desc: your description' above any alias/function in ~/.bashrc to include it automatically.\n"
}
