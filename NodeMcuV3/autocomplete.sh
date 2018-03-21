#/usr/bin/env bash
# source this file in your bash session

AUTOCOMPLETE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

node_mcu_v3_run_completions()
{
  if [[ ${#COMP_WORDS[@]} -ne 2 ]]; then
  	return
  fi
  local options="$(bash "${AUTOCOMPLETE_DIR}/run.sh" shortlist)" 
  local cur
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=( $(compgen -W "${options}" -- ${cur}) )
  return 0
}
complete -F node_mcu_v3_run_completions "run.sh"