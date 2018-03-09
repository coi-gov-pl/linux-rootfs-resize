#!/bin/bash

include validation/bash.bash
include lang/array.bash
include view/colors.bash

LRR_LOG_LEVEL=${LRR_LOG_LEVEL:-INFO}


function logger.__should-print {
  local level="$1"
  local log_levels=('DEBUG' 'INFO' 'WARN' 'ERROR')
  declare -A log_level_values=( ['DEBUG']=1 ['INFO']=2 ['WARN']=3 ['ERROR']=4 )

  if ! array.contains $LRR_LOG_LEVEL "${log_levels[@]}"; then
    echo "Given invalid log level: ${LRR_LOG_LEVEL}, possible values are: ${log_levels[@]}" 1>&2
    exit 1
  fi
  local int_level=${log_level_values[$level]}
  local int_displaying=${log_level_values[$LRR_LOG_LEVEL]}
  (( $int_level >= $int_displaying ))
}

function logger.debug {
  local message="$@"
  if logger.__should-print 'DEBUG'; then
    echo -e "${COLOR_LIGHT_BLUE}DEBUG: ${message}${COLOR_NC}" 1>&2
  fi
}

function logger.info {
  local message="$@"
  if logger.__should-print 'INFO'; then
    echo -e "${COLOR_LIGHT_GRAY}INFO: ${message}${COLOR_NC}" 1>&2
  fi
}

function logger.success {
  local message="$@"
  if logger.__should-print 'INFO'; then
    echo -e "${COLOR_LIGHT_GREEN}${message}${COLOR_NC}" 1>&2
  fi
}

function logger.warn {
  local message="$@"
  if logger.__should-print 'WARN'; then
    echo -e "${COLOR_YELLOW}WARN: ${message}${COLOR_NC}" 1>&2
  fi
}

function logger.error {
  local message="$@"
  if logger.__should-print 'ERROR'; then
    echo -e "${COLOR_RED}ERROR: ${message}${COLOR_NC}" 1>&2
  fi
}
