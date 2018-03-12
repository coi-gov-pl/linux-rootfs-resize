#!/usr/bin/env bash

function executor.stream {
  local command="$@"
  logger.debug "Executing command: ${command}"
  if [ "${LRR_EXEC:-1}" -ne 0 ]; then
    $command
    local ret=$?
  fi
  return $ret
}

function executor.capture {
  local command="$@"
  logger.debug "Executing command: ${command}"
  if [ "${LRR_EXEC:-1}" -ne 0 ]; then
    local output
    output=`$command`
    local ret=$?
  fi
  echo "${output}"
  return $ret
}
