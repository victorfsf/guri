GURI_DOCKER_ICON="@"
GURI_DOT_FILE=".gurirc"
GURI_EXEC_DOT_FILE=false
GURI_SHOW_GIT_STASH=true
GURI_SHOW_EXEC_TIME=true
GURI_MIN_EXEC_TIME=1
GURI_PROMPT_SYMBOL="➜"
GURI_GIT_PROMPT_PREFIX="$fg[white]"
GURI_GIT_PROMPT_SUFFIX=""
GURI_GIT_PROMPT_DIRTY=" $fg_bold[red]"
GURI_GIT_PROMPT_CLEAN=" $fg_bold[white]"
GURI_GIT_PROMPT_AHEAD="$fg[green]⇡"
GURI_GIT_PROMPT_BEHIND="$fg[magenta]⇣"
GURI_GIT_PROMPT_DIVERGED="$GURI_GIT_PROMPT_AHEAD$GURI_GIT_PROMPT_BEHIND"
GURI_PYTHON_VERSION_VENV_COLOR="$FG[122]"
GURI_PYTHON_VERSION_COLOR="$FG[153]"
GURI_VENV_INDICATOR_COLOR="$FG[195]"

ZSH_THEME_GIT_PROMPT_PREFIX="$GURI_GIT_PROMPT_PREFIX"
ZSH_THEME_GIT_PROMPT_SUFFIX="$GURI_GIT_PROMPT_SUFFIX"
ZSH_THEME_GIT_PROMPT_DIRTY="$GURI_GIT_PROMPT_DIRTY"
ZSH_THEME_GIT_PROMPT_CLEAN="$GURI_GIT_PROMPT_CLEAN"
ZSH_THEME_GIT_PROMPT_AHEAD="$GURI_GIT_PROMPT_AHEAD"
ZSH_THEME_GIT_PROMPT_BEHIND="$GURI_GIT_PROMPT_BEHIND"
ZSH_THEME_GIT_PROMPT_DIVERGED="$GURI_GIT_PROMPT_DIVERGED"

VIRTUAL_ENV_DISABLE_PROMPT="yes"

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
    printf "$fg_bold[cyan]$(get_folder_level)»"
    printf "$reset_color $(ssh_prompt_info)$fg[blue]$(get_pwd)"
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
    if [[ "$GURI_SHOW_GIT_STASH" == true ]]; then
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

zenv_prompt_info() {
    if [[ -n "$Z_ENV_NAME" ]]; then
        echo "$fg[green] $Z_UNICODE_SYMBOL"
    fi
}

exec_time_prompt_info() {
    [[ "$GURI_SHOW_EXEC_TIME" == false ]] && return
    if [[ "$GURI_EXEC_TIME" -ge "$GURI_MIN_EXEC_TIME" ]]; then
    	local human_time time_color
    	local days=$(( $GURI_EXEC_TIME / 60 / 60 / 24 ))
    	local hours=$(( $GURI_EXEC_TIME / 60 / 60 % 24 ))
    	local minutes=$(( $GURI_EXEC_TIME / 60 % 60 ))
    	local seconds=$(( $GURI_EXEC_TIME % 60 ))
    	(( days > 0 )) && human_time+="${days}d "
    	(( hours > 0 )) && human_time+="${hours}h "
    	(( minutes > 0 )) && human_time+="${minutes}m "
    	human_time+="${seconds}s"
        if (( hours > 0 || days > 0 )); then
            time_color="$fg_bold[red]"
        elif (( minutes > 0 )); then
            time_color="$fg_bold[magenta]"
        else
            time_color="$fg_bold[cyan]"
        fi
        echo " $time_color$human_time$reset_color"
    fi
}

run_dot_file() {
    if [[ "$GURI_EXEC_DOT_FILE" == true ]] && [[ -f "$GURI_DOT_FILE" ]]; then
        source "$GURI_DOT_FILE"
    fi
}

virtualenv_indicator() {
    if [[ -n "$Z_ENV_NAME" ]]; then
        psvar[1]="${Z_ENV_NAME} "
    elif [[ -n "$VIRTUAL_ENV" ]]; then
        if [[ "$PIPENV_ACTIVE" -eq 1 ]]; then
            psvar[1]="venv "
        else
            psvar[1]="${VIRTUAL_ENV##*/} "
        fi
    else
        psvar[1]=""
    fi
    psvar[2]=" v$(python --version 2>&1 | sed -e "s/Python //")"
}

py_color() {
    [[ -n "$VIRTUAL_ENV" ]] && echo "$GURI_PYTHON_VERSION_VENV_COLOR" || \
        echo "$GURI_PYTHON_VERSION_COLOR"
}

exec_time_start() {
    [[ "$GURI_SHOW_EXEC_TIME" == false ]] && return
    GURI_EXEC_TIME_START="$(date +%s)"
}

exec_time_stop() {
    [[ "$GURI_SHOW_EXEC_TIME" == false ]] && return
    [[ -n "$GURI_EXEC_TIME" ]] && unset GURI_EXEC_TIME
    [[ -z "$GURI_EXEC_TIME_START" ]] && return
    GURI_EXEC_TIME="$(expr $(date +%s) - $GURI_EXEC_TIME_START )"
    unset GURI_EXEC_TIME_START
}

get_ret_status() {
    echo "%(?:%{$fg_bold[green]%}$GURI_PROMPT_SYMBOL:%{$fg_bold[red]%}$GURI_PROMPT_SYMBOL) "
}

add-zsh-hook chpwd run_dot_file
add-zsh-hook precmd virtualenv_indicator

add-zsh-hook preexec exec_time_start
add-zsh-hook precmd exec_time_stop

PROMPT='
$(level_prompt_info)$(git_prompt_info)$(py_color)%2v$(zenv_prompt_info)$(exec_time_prompt_info)
%{$GURI_VENV_INDICATOR_COLOR%}%1v$(get_ret_status)%{$fg_no_bold[white]%}'
