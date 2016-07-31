PATH=$PATH:$HOME/bin
PATH=$PATH:$HOME/.wm/scripts
PATH=$PATH:$HOME/.gem/ruby/2.3.0/bin

# {{{ env
export EDITOR='vim'
export GIT_EDITOR='/usr/bin/vim'
export BROWSER=qutebrowser
export TERMINAL=st
export FILEBROWSER=pcmanfm
# }}}

# {{{ alias
alias tmux='tmux -2' #Make tmux assume 256 colors.
alias cavampd='cava -i fifo -p /tmp/mpd.fifo -b 20'
alias sysinfo='archey3 && dfc -p /dev && colors'
alias ls='ls --color=auto'
# alias vim='vim --servername `date +%s`'
alias vim='emacs -nw'
alias paste="curl -F 'sprunge=<-' http://sprunge.us"
alias grep="grep --color=auto"
alias pacman="pacman --color=always"
alias make="clear && make"
alias shot="scrot ~/Screenshots/`date +%y-%m-%d-%H:%M:%S`.png"
alias getip="curl -s checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//'"
# }}}

# {{{ func
setgitremote() {
    # I found myself doing this too often.
    # todo: this better
    local remoteUrl="$(git remote -v | grep -oP "http[^ ]+" | head -1)"
    local domain="$(echo $remoteUrl | cut -f3 -d'/')"
    local username="$(echo $remoteUrl | cut -f4 -d'/')"
    local reponame="$(echo $remoteUrl | cut -f5 -d'/' | cut -f1 -d'.' )"
    local newRemote="git@$domain:$username/$reponame.git"
    echo Setting git remote to $newRemote
    git remote set-url origin $newRemote
}

extract() {      # Handy Extract Program
    if [ -f $1 ] ; then
        case $1 in
            *.tar.bz2)   tar xvjf $1     ;;
            *.tar.gz)    tar xvzf $1     ;;
            *.bz2)       bunzip2 $1      ;;
            *.rar)       unrar x $1      ;;
            *.gz)        gunzip $1       ;;
            *.tar)       tar xvf $1      ;;
            *.tbz2)      tar xvjf $1     ;;
            *.tgz)       tar xvzf $1     ;;
            *.zip)       unzip $1        ;;
            *.Z)         uncompress $1   ;;
            *.7z)        7z x $1         ;;
            *)           echo "'$1' cannot be extracted via >extract<" ;;
        esac
    else
        echo "'$1' is not a valid file!"
    fi
}

prompt ()
{
    _ERR=$?
    _prompt=">"
    [ $(jobs | wc -l) -ne 0 ] && _prompt="$_promp$_prompt"
    [ $_ERR -ne 0 ] && _prompt="\e[7m$_prompt\e[0m" # invert
    echo -e -n "$_prompt "
}
# }}}

# {{{ shell
cur_shell=$(ps | grep $$ |  sed 's/^.* //')
historyLength=6000

HISTFILE="$HOME/.${cur_shell}_history"
case $cur_shell in
    bash)
        HISTSIZE=200
        HISTFILESIZE=$historyLength
        HISTCONTROL=ignoredups:erasedups
        ;;
    zsh)
        setopt hist_ignore_dups
        SAVEHIST=$historyLength
        ;;
esac
# }}}

# autostartx if running on the first tty:
[[ -z $DISPLAY && $XDG_VTNR -eq 1 && -z $TMUX ]] && exec startx
