#!/usr/bin/env bash

include logger.bash

function executor.stream {
  local command="$@"
  logger.debug "Executing command: ${command}"
  if [ "${LRR_EXEC:-1}" -ne 0 ]; then
    eval $command
    local ret=$?
  fi
  return $ret
}

function executor.capture {
  local command="$@"
  logger.debug "Executing command: ${command}"
  if [ "${LRR_EXEC:-1}" -ne 0 ]; then
    local output
    local tmpscript=$(mktemp -t exec-XXXXXX.sh)
    echo "${command}" > ${tmpscript}
    output=`bash ${tmpscript} 2>&1`
    local ret=$?
    rm -rf ${tmpscript}
  fi
  echo "${output}"
  return $ret
}

function executor.silently {
  local command="$@"
  local output=$(executor.capture ${command})
  local ret=$?
  if [ $ret -eq 0 ]; then
    logger.debug "${output}"
  else
    logger.error "${output}"
    exit $ret
  fi
}
