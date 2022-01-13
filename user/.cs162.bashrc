# Save multi-line commands as one command
shopt -s cmdhist

# Increase history length
HISTSIZE=50000
HISTFILESIZE=100000

# Don't record some commands
export HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:clear"

# Display matches for ambiguous patterns at first tab press
bind "set show-all-if-ambiguous on"

# Set default editor
export EDITOR='vim'

# Set `man`'s section search order so that C stdlib functions
# and syscalls appear as the default result. This is helpful for students,
# since otherwise they would need to manually specify a section number in
# some cases (e.g. for `write`, which is both a user program and a syscall).
export MANSECT='2:3:3posix:1:n:l:8:3pm:3perl:3am:5:4:9:6:7'

# Exclude .git dir in grep, fgrep, egrep
if [ -x /usr/bin/dircolors ]; then
    alias grep='grep --color=auto --exclude-dir=.git'
    alias fgrep='fgrep --color=auto --exclude-dir=.git'
    alias egrep='egrep --color=auto --exclude-dir=.git'
fi

# Update shell format
black="\[\033[0m\]"
red="\[\033[0;31m\]"
green="\[\033[0;32m\]"
yellow="\[\033[0;33m\]"
blue="\[\033[0;34m\]"
purple="\[\033[0;35m\]"
PS1="$blue\u@\h$black [$green\t$black] $red\W$black \$ "

# Add .bin to PATH.
export PATH=$PATH:$HOME/.bin

# fzf
[ -f ~/.fzf.bash ] && source ~/.fzf.bash
