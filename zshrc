export ZPLUG_HOME=~/.zplug
source $ZPLUG_HOME/init.zsh

zplug "zsh-users/zsh-syntax-highlighting"
zplug "zsh-users/zsh-completions"
zplug "zsh-users/zsh-autosuggestions"
zplug "zsh-users/zsh-history-substring-search"
zplug "zsh-users/zaw"
zplug "yonchu/3935922", from:gist, use:chpwd_for_zsh.sh
zplug "zchee/zsh-completions"

if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi
zplug load --verbose

export LANG=ja_JP.UTF-8
setopt nolistbeep
autoload -Uz compinit
compinit
alias ls='ls -G'
alias ll='ls -alh'
alias la='ls -a'
export PATH=$PATH:~/nvim-osx64/bin
alias vim='~/nvim-osx64/bin/nvim -p'
export EDITOR=vim

chpwd_functions=($chpwd_functions dirs)
source /usr/local/share/zsh/site-functions

# auto suggestions setting
bindkey '^f' autosuggest-accept

if zplug check "zsh-users/zsh-history-substring-search"; then
    bindkey '^P' history-substring-search-up
    bindkey '^N' history-substring-search-down
    bindkey -M vicmd 'k' history-substring-search-up
    bindkey -M vicmd 'j' history-substring-search-down
fi

# zaw setting
if zplug check "zsh-users/zaw"; then
    autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
    add-zsh-hook chpwd chpwd_recent_dirs
    zstyle ':chpwd:*' recent-dirs-max 500 # cdrの履歴を保存する個数
    zstyle ':chpwd:*' recent-dirs-default yes
    zstyle ':completion:*' recent-dirs-insert both
    bindkey '^@' zaw-src-cdr
    bindkey '^R' zaw-history
    bindkey '^X^F' zaw-git-files
    bindkey '^X^B' zaw-git-branches
    bindkey '^X^P' zaw-process
    zstyle ':filter-select' case-insensitive yes
    zstyle ':filter-select' max-lines 10 # use 10 lines for filter-select
    zstyle ':filter-select' max-lines -10 # use $LINES - 10 for filter-select
    zstyle ':filter-select' rotate-list yes # enable rotation for filter-select
    zstyle ':filter-select' extended-search yes # see below
    zstyle ':filter-select' hist-find-no-dups yes # ignore duplicates in history source
    zstyle ':filter-select:highlight' selected fg=black,bg=white,standout
fi

zstyle ':completion:*' menu select
zstyle ':completion:*' format '%F{white}%d%f'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' keep-prefix
zstyle ':completion:*' completer _oldlist _complete _match _ignored _approximate _list _history
zstyle ':completion:*' list-colors ''
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([%0-9]#)*=0=01;31'

HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000
setopt hist_ignore_dups
setopt share_history

########################################
#プロンプトの設定
########################################

#branch名を表示する
autoload -Uz add-zsh-hook
autoload -Uz colors
colors
autoload -Uz vcs_info

zstyle ':vcs_info:*' enable git svn hg bzr
zstyle ':vcs_info:*' formats '[%b]'
zstyle ':vcs_info:*' actionformats '[%b|%a]'
zstyle ':vcs_info:(svn|bzr):*' branchformat '%b:r%r'
zstyle ':vcs_info:bzr:*' use-simple true
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr "need to commit"    # 適当な文字列に変更する
zstyle ':vcs_info:git:*' unstagedstr "need to add"  # 適当の文字列に変更する
zstyle ':vcs_info:git:*' formats '%m [%b] %c%u'
zstyle ':vcs_info:git:*' actionformats '[%b|%a] %c%u'
zstyle ':vcs_info:git*+set-message:*' hooks git-account git-untracked git-st

+vi-git-account() {
 local email
 email=$(git config user.email)
 hook_com[misc]+=${email}
}


+vi-git-untracked(){
    if [[ $(git rev-parse --is-inside-work-tree 2> /dev/null) == 'true' ]] && \
        git status --porcelain | grep '??' &> /dev/null ; then
        # This will show the marker if there are any untracked files in repo.
        # If instead you want to show the marker only if there are untracked
        # files in $PWD, use:
        #[[ -n $(git ls-files --others --exclude-standard) ]] ; then
        hook_com[staged]+='T'
    fi
}

function +vi-git-st() {
    local ahead behind
    local -a gitstatus

    # for git prior to 1.7
    # ahead=$(git rev-list origin/${hook_com[branch]}..HEAD | wc -l)
    ahead=$(git rev-list ${hook_com[branch]}@{upstream}..HEAD 2>/dev/null | wc -l)
    (( $ahead )) && gitstatus+=( "+${ahead}" )

    # for git prior to 1.7
    # behind=$(git rev-list HEAD..origin/${hook_com[branch]} | wc -l)
    behind=$(git rev-list HEAD..${hook_com[branch]}@{upstream} 2>/dev/null | wc -l)
    (( $behind )) && gitstatus+=( "-${behind}" )

    hook_com[misc]+=${(j:/:)gitstatus}
}

function _update_vcs_info_msg() {
    psvar=()
    LANG=en_US.UTF-8 vcs_info
    [[ -n "$vcs_info_msg_0_" ]] && psvar[1]="$vcs_info_msg_0_"
}
add-zsh-hook precmd _update_vcs_info_msg

case ${UID} in
0)
    PROMPT="[%~]%1(v|%F{green}%1v%f|)
%{$fg[cyan]%}%n%%%{$reset_color%} "
    PROMPT2="%B%{$fg[cyan]%}%_#%{$reset_color%}%b "
    SPROMPT="%B%{$fg[red]m%}%r is correct? [n,y,a,e]:%{$reset_color%}%b "
    [ -n "${REMOTEHOST}${SSH_CONNECTION}" ] && 
        PROMPT="%{[37m%}${HOST%%.*} ${PROMPT}"
    ;;
*)
    PROMPT="[%~]%1(v|%F{green}%1v%f|)
%{$fg[cyan]%}%n%%%{$reset_color%} "
    PROMPT2="%{$fg[cyan]%}%_%%%{$reset_color%} "
    SPROMPT="%{$fg[red]%}%r is correct? [n,y,a,e]:%{$reset_color%} "
    [ -n "${REMOTEHOST}${SSH_CONNECTION}" ] && 
        PROMPT="%{[37m%}${HOST%%.*} ${PROMPT}"
    ;;
esac

#ターミナルのタイトルの設定
case "${TERM}" in
kterm*|xterm)
    precmd() {
        echo -ne "\033]0;${USER}@${HOST%%.*}:${PWD}\007"
    }
    ;;
esac

##############################

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/knsh14/google-cloud-sdk/path.zsh.inc' ]; then source '/Users/knsh14/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/knsh14/google-cloud-sdk/completion.zsh.inc' ]; then source '/Users/knsh14/google-cloud-sdk/completion.zsh.inc'; fi

export PATH=$PATH:/usr/local/share/git-core/contrib/diff-highlight

eval "$(direnv hook zsh)"

export JAVA_HOME=/Library/Java/JavaVirtualMachines/openjdk-12.0.1.jdk/Contents/Home

precmd() {
   pwd=$(pwd)
   cwd=${pwd##*/}
   print -Pn "\e]0;$cwd\a"
}

source <(kubectl completion zsh)
autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /usr/local/bin/kustomize kustomize
source <(rustup completions zsh cargo)


test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
