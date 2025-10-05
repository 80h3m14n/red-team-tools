# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
#[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    #alias grep='grep --color=auto'
    #alias fgrep='fgrep --color=auto'
    #alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
#alias ll='ls -l'
#alias la='ls -A'
#alias l='ls -CF'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi


. "$HOME/.cargo/env"
export PATH=$PATH:/home/ryan/Android/Sdk/platform-tools/
export PATH=$PATH:/home/ryan/Android/Sdk/cmdline-tools/latest/bin/
export PATH=$PATH:/home/ryan/Apps/android-studio/bin/
export PATH=$PATH:/usr/local/go/bin
export GOROOT=/usr/local/go
export PATH=$GOROOT/bin:$PATH
export PATH=$PATH:/home/ryan/Apps/flutter/bin/
export DOCKER_HOST=unix:///var/run/docker.sock
export CHROME_EXECUTABLE=/usr/bin/brave-browser

export PYENV_ROOT="$HOME/.pyenv"
[[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - bash)"
eval "$(pyenv virtualenv-init -)"
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init - bash)"

# pnpm
export PNPM_HOME="/home/ryan/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end




# Alias apt - nala
# Nala is modern with prettier output, better dependency resolution info, and faster downloads
# Nala uses parallel fetching 
apt() { 
  command nala "$@"
}
sudo() {
  if [ "$1" = "apt" ]; then
    shift
    command sudo nala "$@"
  else
    command sudo "$@"
  fi
}


# Clean reverse DNS lookup shortcut, powered by THC’s public IP tool 
rdns () {
    curl -m10 -fsSL "https://ip.thc.org/${1:?}?limit=20&f=${2}"
}

# Prepend shims to PATH
# Hijacks Python-related stuff (and tools installed via pip/pyenv) 
# Tell's the system to cheeck ~/.pyenv/shims  before /usr/bin
export PATH="$HOME/.pyenv/shims:$PATH"  


# Highlights only externally reachable ports
# Usage:
# 1. All open ports, type: ports 
# 2. List only public-facing ports, type: ports | grep "Public"

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



# Mini termial help menu
function helpme() {
    echo -e "\n\033[1;36mAvailable Custom Commands:\033[0m\n"

    echo -e "\033[1;33mports\033[0m      → Lists all open ports with visibility (Public/Private/Loopback)."
    echo -e "                 Usage: ports | grep 'Public'  # show only public ports\n"

    echo -e "\033[1;33mrdns <ip>\033[0m  → Reverse DNS lookup using THC’s public IP tool."
    echo -e "                 Example: rdns 8.8.8.8\n"

    echo -e "\033[1;33mapt / sudo apt\033[0m → Aliased to use nala instead of apt for faster, cleaner installs.\n"

    echo -e "\033[1;33mpyenv / rbenv\033[0m → Environment managers for Python and Ruby (already loaded).\n"

    echo -e "\033[1;33mpnpm\033[0m       → Node package manager (PATH pre-configured).\n"

    echo -e "\033[1;33mhelpme\033[0m     → Shows this menu.\n"

    echo -e "\033[1;32mTip:\033[0m You can edit ~/.bashrc to add your own aliases and drop them into this list.\n"
}


