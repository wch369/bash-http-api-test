# Bash completion for api-test.sh
# Source this file in your shell:
#   source /home/wch/app/bash-http-api-test/completion.sh
# Or add to ~/.bashrc:
#   source /home/wch/app/bash-http-api-test/completion.sh

_api_test_commands() {
    local cur prev words cword
    _init_completion || return

    local commands="init send dry-run show-vars create-env create-template create-xml-template list-envs list-templates version help"
    local template_cmds="send dry-run show-vars"

    if [[ $cword -eq 1 ]]; then
        COMPREPLY=($(compgen -W "$commands" -- "$cur"))
        return
    fi

    if [[ $cword -eq 2 ]]; then
        for cmd in $template_cmds; do
            if [[ "${words[1]}" == "$cmd" ]]; then
                local templates_dir="$(dirname "${words[0]}")/templates"
                if [[ -d "$templates_dir" ]]; then
                    local templates=$(ls "$templates_dir"/*.json 2>/dev/null | xargs -n1 basename | sed 's/\.json$//')
                    COMPREPLY=($(compgen -W "$templates" -- "$cur"))
                fi
                return
            fi
        done
    fi
}

complete -F _api_test_commands api-test.sh
complete -F _api_test_commands ./api-test.sh
