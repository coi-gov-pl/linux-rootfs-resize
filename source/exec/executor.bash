#!/usr/bin/env bash

include logger.bash

function executor.stream {
  local command
  command="$@"
  logger.debug "Executing command: ${command}"
  if [ "${LRR_EXEC:-1}" -ne 0 ]; then
    eval $command
  fi
}

function executor.capture {
  local command
  command="$@"
  logger.debug "Executing command: ${command}"
  if [ "${LRR_EXEC:-1}" -ne 0 ]; then
    local output
    local tmpscript
    tmpscript=$(mktemp -t exec-XXXXXX.sh)
    echo "${command}" > ${tmpscript}
    set +e
    output=`bash ${tmpscript} 2>&1`
    local ret
    ret=$?
    set -e
    rm -rf ${tmpscript}
  fi
  echo "${output}"
  return $ret
}

function executor.silently {
  local command
  command="$@"
  local output
  set +e
  output=$(executor.capture ${command})
  local ret
  ret=$?
  set -e
  if [ $ret -eq 0 ]; then
    logger.debug "${output}"
  else
    logger.error "${output}"
    exit $ret
  fi
}
