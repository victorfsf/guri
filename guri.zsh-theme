
get_pwd() {
    if [[ "$PWD" == "$HOME" ]]; then
        echo "~"
    else
        echo "$(basename $PWD)"
    fi
}

get_folder_level() {
    echo "$(expr $(grep -o '/' <<< "$PWD" | grep -c .) - 1)"
}

ssh_prompt_info() {
    if [[ -n "$SSH_CONNECTION" ]]; then
        echo "$fg[magenta]%n@%m » "
    elif [[ "$USER" == "root" ]]; then
        echo "$fg[red]%n » "
    fi
}

level_prompt_info() {
    echo "$fg_bold[cyan]$(get_folder_level)»$reset_color $(ssh_prompt_info)$fg[blue]$(get_pwd)"
}

git_prompt_info() {
    ref=$(git symbolic-ref HEAD 2> /dev/null) || return 0
    command git -c gc.auto=0 fetch &>/dev/null 2>&1 &|
    local index=$(command git status --porcelain -b 2> /dev/null)

    local git_status
    if $(echo "$index" | grep '^## .*ahead* .*behind' &> /dev/null); then
        git_status=" $ZSH_THEME_GIT_PROMPT_DIVERGED"
    elif $(echo "$index" | grep '^## .*ahead' &> /dev/null); then
        git_status=" $ZSH_THEME_GIT_PROMPT_AHEAD"
    elif $(echo "$index" | grep '^## .*behind' &> /dev/null); then
        git_status=" $ZSH_THEME_GIT_PROMPT_BEHIND"
    fi

    local git_stash
    if [[ "$GURI_SHOW_GIT_STASH" -eq 1 ]]; then
        git_stash="$(command git stash list | wc -l)"
        if [[ "$git_stash" > 0 ]]; then
            git_stash="$reset_color$fg[magenta]+$git_stash $fg_bold[white]"
        else
            git_stash=" "
        fi
    else
        git_stash=" "
    fi

    printf "$(parse_git_dirty)$git_stash"
    printf "$ZSH_THEME_GIT_PROMPT_PREFIX$(current_branch)"
    printf "$ZSH_THEME_GIT_PROMPT_SUFFIX$git_status$reset_color"
}

docker_machine_prompt_info() {
    if [[ -n "$DOCKER_MACHINE_NAME" ]]; then
        echo "$fg[green] $GURI_DOCKER_ICON$DOCKER_MACHINE_NAME"
    fi
}

virtualenv_indicator() {
    if [[ -n "$VIRTUAL_ENV" ]]; then
        psvar[1]="${VIRTUAL_ENV##*/} "
        psvar[2]=" v$(python --version 2>&1 | sed -e "s/Python //")"
    else
        psvar[1]=""
        psvar[2]=""
    fi
}

run_dot_file() {
    if [[ "$GURI_EXEC_DOT_FILE" -eq 1 ]] && [[ -f "$GURI_DOT_FILE" ]]; then
        source "$GURI_DOT_FILE"
    fi
}

local ret_status="%(?:%{$fg_bold[green]%}➜ :%{$fg_bold[red]%}➜ )"

GURI_DOCKER_ICON="@"
GURI_DOT_FILE=".guri"
GURI_EXEC_DOT_FILE=1
GURI_SHOW_GIT_STASH=1
ZSH_THEME_GIT_PROMPT_PREFIX="$fg[white]"
ZSH_THEME_GIT_PROMPT_SUFFIX=""
ZSH_THEME_GIT_PROMPT_DIRTY=" $fg_bold[red]"
ZSH_THEME_GIT_PROMPT_CLEAN=" $fg_bold[white]"
ZSH_THEME_GIT_PROMPT_AHEAD="$fg[green]⇡"
ZSH_THEME_GIT_PROMPT_BEHIND="$fg[magenta]⇣"
ZSH_THEME_GIT_PROMPT_DIVERGED="$ZSH_THEME_GIT_PROMPT_AHEAD$ZSH_THEME_GIT_PROMPT_BEHIND"
VIRTUAL_ENV_DISABLE_PROMPT="yes"

add-zsh-hook precmd run_dot_file
add-zsh-hook precmd virtualenv_indicator

PROMPT='
$(level_prompt_info)$(git_prompt_info)$fg[yellow]%2v$(docker_machine_prompt_info)
$reset_color%1v${ret_status}$reset_color'
