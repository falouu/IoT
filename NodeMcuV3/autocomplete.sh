#/usr/bin/env bash
# source this file in your bash session

AUTOCOMPLETE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

node_mcu_v3_run_completions()
{
  local options="$(bash "${AUTOCOMPLETE_DIR}/run.sh" shortlist)" 
  local cur
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=( $(compgen -W "${options}" -- ${cur}) )
  echo "${COMPREPLY}" > compreply

  return 0
}
complete -o nospace -F node_mcu_v3_run_completions ./run.sh