# If not running interactively, don't do anything
[[ $- != *i* ]] && return

. $HOME/.profile

[ ! -d ~/.zplug ] && curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh

. ~/.zplug/init.zsh

zplug "plugins/git", from:oh-my-zsh                                  # git aliases
zplug "zsh-users/zsh-autosuggestions", use:"zsh-autosuggestions.zsh" # fish-like suggestions
zplug "djui/alias-tips"                                              # alias reminder

zplug "plugins/pass", from:oh-my-zsh                                 # completions for pass
zplug "spwhitt/nix-zsh-completions"                                  # completions for nix
zplug "plugins/lein", from:oh-my-zsh                                 # completions for lein
zplug "zsh-users/zsh-completions"                                    # completions for everything else

if has fzf; then
    zplug "junegunn/fzf", use:"shell/completion.zsh"                 # fzf
    zplug "junegunn/fzf", use:"shell/key-bindings.zsh"               # fzf
fi

# considering
zplug "plugins/catimg", from:oh-my-zsh                               # term image rendering
zplug "plugins/gitignore", from:oh-my-zsh                            # access default gitignores, from gitignore.io api. (gi)
zplug "plugins/jsontools", from:oh-my-zsh                            # json helpers, {pp,is,urlencode,urldecode}_json

# maybe:
# https://github.com/robbyrussell/oh-my-zsh/tree/master/plugins/per-directory-history
# https://github.com/robbyrussell/oh-my-zsh/tree/master/plugins/wd

zplug check || zplug install
zplug load

setopt PROMPT_SUBST

# completion like emacs, use cache
zstyle ':completion:*:default' menu select=1
zstyle ':completion:*' use-cache true

# completion after '='(like --prefix=/usr)
setopt magic_equal_subst

# case insensitive path completion
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# if the entry is not a command but matches dir, cd to that dir.
setopt autocd

# Remove '/' and '-' from $WORDCHARS for finer Ctrl-w behaviour
export WORDCHARS='*?_.[]~=&;!#$%^(){}<>'

# vim bindings
bindkey -v

zle-keymap-select () {
    if [ $KEYMAP = vicmd ]; then
        cursorStyle block
    else
        cursorStyle bar
    fi
    zle reset-prompt
    zle -R
}
zle -N zle-keymap-select

zle-line-init () {
    zle -K viins
    cursorStyle bar
}
zle -N zle-line-init

# text object extension -- eg ci" da(:
autoload -U select-quoted
zle -N select-quoted
for m in visual viopp; do
    for c in {a,i}{\',\",\`}; do
        bindkey -M $m $c select-quoted
    done
done

# match escape to evil
bindkey fd vi-cmd-mode

# match some standard readline binds in insert mode
bindkey '^P' up-history
bindkey '^N' down-history
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char
bindkey '^w' backward-kill-word
bindkey '^a' beginning-of-line
bindkey '^e' end-of-line

# TODO: map this to fzf (plugin above is bindkey -e setup)
bindkey '^r' history-incremental-search-backward
