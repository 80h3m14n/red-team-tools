# .bashrc

# ============================================================
# Global definitions
# ============================================================

if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi


# ============================================================
# PATH
# ============================================================

# desc: Add a directory to PATH (only if it isn't already present).
path_add() {
    case ":$PATH:" in
        *":$1:"*) ;;
        *) PATH="$1:$PATH" ;;
    esac
}

# User binaries
path_add "$HOME/.local/bin"
path_add "$HOME/bin"

# Go
path_add "$HOME/go/bin"

# Nim
path_add "$HOME/.nimble/bin"

# Gradle
path_add "/opt/gradle/bin"

# Metasploit
path_add "/opt/metasploit-framework/bin"

# Android SDK
export ANDROID_HOME="$HOME/Utilities/Android/Sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"

path_add "$ANDROID_HOME/cmdline-tools/latest/bin"
path_add "$ANDROID_HOME/emulator"
path_add "$ANDROID_HOME/platform-tools"


export PATH

# desc: inspect PATH properly
path() {
    printf '%s\n' "$PATH" | tr ':' '\n' | nl
}


# ============================================================
# Mise
# ============================================================

# Mise manages Python, Ruby, Rust, Node, etc.
# desc: unified multi-language version manager
eval "$(mise activate bash)"


# ============================================================
# History
# ============================================================

# Better history behavior:
# Prevent duplicate spam, preserve history across sessions,
# and clean duplicate command recall.
HISTSIZE=1000
HISTFILESIZE=2000
HISTCONTROL=ignoreboth:erasedups
shopt -s histappend


# ============================================================
# Shell behavior
# ============================================================

# Case-insensitive globbing
shopt -s nocaseglob

# Fix small typos in cd
shopt -s cdspell

# Auto cd (type folder name directly)
# Set and unset shell options.
# shopt -s autocd


# ============================================================
# User-specific aliases and functions
# ============================================================

if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc


# desc: Reload bashrc file
alias reload='source ~/.bashrc'


# ============================================================
# Git shortcuts
# ============================================================

# desc: git status
alias gs='git status'
# desc: git add
alias ga='git add'
# desc: git commit
alias gc='git commit'
# desc: git push
alias gp='git push'
# desc: git log
alias gl='git log --oneline --graph --decorate'
# desc: git diff
alias gd='git diff'

# ============================================================
# Python
# ============================================================

# Prevent Python from creating __pycache__ / .pyc files
export PYTHONDONTWRITEBYTECODE=1


# ============================================================
# GPG agent
# ============================================================

export GPG_TTY=$(tty)
gpg-connect-agent updatestartuptty /bye >/dev/null


# ============================================================
# Starship: Shell output formatter
# ============================================================

eval "$(starship init bash)"


# ============================================================
# fzf
# ============================================================

# desc: fast fuzzy finder
eval "$(fzf --bash)"


# desc: fuzzy kill process
fkill() {
    local pid

    pid=$(ps -eo pid,comm --sort=-%cpu |
        fzf --height 40% --reverse |
        awk '{print $1}')

    [[ -n "$pid" ]] && kill "$pid"
}

# ============================================================
# zoxide
# ============================================================

# desc: a smarter cd command
eval "$(zoxide init bash)"

# Example usage: z /Doc # finds and cd to directory with Doc


# ============================================================
# Network commands
# ============================================================

# desc: Reverse DNS lookup via THC's public IP tool
rdns() {

    curl -m10 -fsSL "https://ip.thc.org/${1:?}?limit=20&f=${2}"
}


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


# ============================================================
# SSH host auto complete
# ============================================================

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


# ============================================================
# ripgrep + fzf
# ============================================================

# desc: Search inside files with preview (rg + fzf)
rgi() {
    rg --line-number --color=always --smart-case "${1:-}" |
        fzf --ansi \
            --preview 'bat --style=numbers --color=always {1} --line-range {2}:+20' \
            --delimiter ':' \
            --nth 3..
}

# ============================================================
# myip
# ============================================================

# desc: Show public and local IP Address
myip() {
    echo "Local:"
    ip -br addr show

    echo
    echo "Public:"
    curl -fsS https://api.ipify.org
    echo
}

# ============================================================
# sysinfo
# ============================================================

# desc: Machine overview/system information
sysinfo() {
    clear
    echo "🖥️  Host:     $(hostname)"
    echo "🐧 OS:       $(. /etc/os-release && echo "$PRETTY_NAME")"
    echo "🧠 Kernel:   $(uname -r)"
    echo "🏗️  Arch:     $(uname -m)"
    echo "⏱️  Uptime:   $(uptime -p)"
    echo "💾 Memory:   $(free -h | awk '/^Mem:/ {print $3 " / " $2}')"
    echo "💽 Disk:     $(df -h / | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}')"
}

# ============================================================
# Help menu
# ============================================================

# desc: Mini terminal help menu
function helpme() {
    echo -e "\n\033[1;36m🧩  Custom Commands, Functions, and Aliases\033[0m\n"


    # Aliases
    # ========================================================

    echo -e "\033[1;33mAliases:\033[0m"

    awk '
        /^# desc:/ {
            desc=$0
            sub(/^# desc:[[:space:]]*/, "", desc)
            next
        }

        /^alias[[:space:]]+/ {
            name=$2
            sub(/=.*/, "", name)

            printf "  \033[1;32m%-15s\033[0m - %s\n",
                   name,
                   (desc ? desc : "(no description)")

            desc=""
        }

        !/^#/ && !/^alias[[:space:]]+/ {
            desc=""
        }
    ' ~/.bashrc

    echo ""


    # Functions
    # ========================================================

    echo -e "\033[1;33mFunctions:\033[0m"

    awk '
        /^# desc:/ {
            desc=$0
            sub(/^# desc:[[:space:]]*/, "", desc)
            next
        }

        /^[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\(\)[[:space:]]*\{/ {
            name=$0
            sub(/[[:space:]]*\(.*/, "", name)

            printf "  \033[1;35m%-15s\033[0m - %s\n",
                   name,
                   (desc ? desc : "(no description)")

            desc=""
        }

        /^function[[:space:]]+[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\(/ {
            name=$0
            sub(/^function[[:space:]]+/, "", name)
            sub(/[[:space:]]*\(.*/, "", name)

            printf "  \033[1;35m%-15s\033[0m - %s\n",
                   name,
                   (desc ? desc : "(no description)")

            desc=""
        }

        !/^#/ &&
        !/^alias[[:space:]]+/ &&
        !/^[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\(\)/ &&
        !/^function[[:space:]]+/ {
            desc=""
        }
    ' ~/.bashrc

    echo ""

    # ========================================================
    # Usage
    # ========================================================

    echo -e "\033[1;34mUsage:\033[0m"
    echo "  Type the alias or function name directly to use it."
    echo -e "  Example: \033[1;32mports\033[0m  → Show open ports with visibility."
    echo -e "  Example: \033[1;32mrdns 8.8.8.8\033[0m  → Reverse DNS lookup."
    echo -e "  Pipe with other commands: \033[1;32mports | grep \"Public\"\033[0m"

    echo ""
    echo -e "\033[1;90mHint:\033[0m Add '# desc: description' before an alias or function to document it."
}
