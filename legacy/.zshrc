export EDITOR=vim
export PATH=$PATH:~/peco_linux_amd64

## search
HISTSIZE=150000
SAVEHIST=150000
setopt hist_ignore_dups     # ignore duplication command history list
setopt share_history        # share command history data
stty -ixon #for ^S
function peco-history-selection() {
    BUFFER=`history -n 1 | sort -r  | awk '!a[$0]++' | peco`
    CURSOR=$#BUFFER
    zle reset-prompt
}

zle -N peco-history-selection
bindkey '^R' peco-history-selection


# show git branch(https://qiita.com/mikan3rd/items/d41a8ca26523f950ea9d)
source ~/.zsh/git-prompt.sh
zstyle ':completion:*:*:git:*' script ~/.zsh/git-completion.zsh
autoload -Uz compinit && compinit
GIT_PS1_SHOWDIRTYSTATE=true
setopt PROMPT_SUBST ; PS1='%F{green}%n@%m%f: %F{cyan}%~%f %F{red}$(__git_ps1 "(%s)")%f
\$ '
setopt PROMPT_SUBST ; PS1='%F{cyan}%~%f %F{red}$(__git_ps1 "--%s")%f %F{blue}$(date "+%Y-%m-%d %H:%M:%S")%f 
 \$ '
