#!/usr/bin/env bash
# source this file in your bash session


node_mcu_v3_run_completions()
{
  if [[ ${#COMP_WORDS[@]} -eq 2 ]]; then
      local options="$(bash "${ROOT_DIR}/run.sh" shortlist)"
  elif [[ ${#COMP_WORDS[@]} -eq 3 ]]; then
      local command="${COMP_WORDS[1]}"
      local options="$(bash "${ROOT_DIR}/run.sh" help --command ${command} --params-only)"
  else
      return
  fi

  local cur
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=( $(compgen -W "${options}" -- ${cur}) )

}
complete -F node_mcu_v3_run_completions "run.sh"