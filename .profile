alias ll='ls -al -G'

GREEN="\e[0;32m"
BLUE="\e[0;34m"
RED="\e[0;31m"
YELLOW="\e[0;33m"
COLOREND="\e[00m"

parse_remote_state() {
    remote_state=$(git status -sb 2> /dev/null | grep -oh "\[.*\]")
    if [[ "$remote_state" != "" ]]; then
        out=""
        if [[ "$remote_state" == *ahead* ]] && [[ "$remote_state" == *behind* ]]; then
            behind_num=$(echo "$remote_state" | grep -oh "behind \d*" | grep -oh "\d*$")
            ahead_num=$(echo "$remote_state" | grep -oh "ahead \d*" | grep -oh "\d*$")
            out=" ${RED}-$behind_num${COLOREND},${GREEN}+$ahead_num${COLOREND}"
        elif [[ "$remote_state" == *ahead* ]]; then
            ahead_num=$(echo "$remote_state" | grep -oh "ahead \d*" | grep -oh "\d*$")
            out=" ${GREEN}+$ahead_num${COLOREND}"
        elif [[ "$remote_state" == *behind* ]]; then
            behind_num=$(echo "$remote_state" | grep -oh "behind \d*" | grep -oh "\d*$")
            out=" ${RED}-$behind_num${COLOREND}"
        fi

        echo "$out"
    fi
}

get_git_branch() {
    local s='';
    local branchName='';

    # Check if the current directory is in a Git repository.
    if [ $(git rev-parse --is-inside-work-tree &>/dev/null; echo "${?}") == '0' ]; then

        # check if the current directory is in .git before running git checks
        if [ "$(git rev-parse --is-inside-git-dir 2> /dev/null)" == 'false' ]; then

            # Ensure the index is up to date.
            git update-index --really-refresh -q &>/dev/null;

            # Check for uncommitted changes in the index.
            if ! $(git diff --quiet --ignore-submodules --cached); then
                s+='+';
            fi;

            # Check for unstaged changes.
            if ! $(git diff-files --quiet --ignore-submodules --); then
                s+='!';
            fi;

            # Check for untracked files.
            if [ -n "$(git ls-files --others --exclude-standard)" ]; then
                s+='?';
            fi;

            # Check for stashed files.
            if $(git rev-parse --verify refs/stash &>/dev/null); then
                s+='$';
            fi;

        fi;

        # Get the short symbolic ref.
        # If HEAD isn’t a symbolic ref, get the short SHA for the latest commit
        # Otherwise, just give up.
        branchName=":$(git symbolic-ref --quiet --short HEAD 2> /dev/null || \
            git rev-parse --short HEAD 2> /dev/null || \
            echo '(unknown)')";

        [ -n "${s}" ] && s=" ${s}";

        echo "${GREEN}${branchName}$(parse_remote_state)${COLOREND}${RED}${s}${COLOREND}";
    else
        return;
    fi;
}

prompt() {
    PS1="${GREEN}λ${COLOREND} \W$(get_git_branch) ${GREEN}→${COLOREND} "
}

PROMPT_COMMAND=prompt
