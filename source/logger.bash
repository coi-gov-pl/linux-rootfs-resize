#!/bin/bash

include validation/bash.bash
include lang/array.bash

LRR_LOG_LEVEL=${LRR_LOG_LEVEL:-INFO}

export COLOR_NC='\e[0m' # No Color
export COLOR_WHITE='\e[1;37m'
export COLOR_BLACK='\e[0;30m'
export COLOR_BLUE='\e[0;34m'
export COLOR_LIGHT_BLUE='\e[1;34m'
export COLOR_GREEN='\e[0;32m'
export COLOR_LIGHT_GREEN='\e[1;32m'
export COLOR_CYAN='\e[0;36m'
export COLOR_LIGHT_CYAN='\e[1;36m'
export COLOR_RED='\e[0;31m'
export COLOR_LIGHT_RED='\e[1;31m'
export COLOR_PURPLE='\e[0;35m'
export COLOR_LIGHT_PURPLE='\e[1;35m'
export COLOR_BROWN='\e[0;33m'
export COLOR_YELLOW='\e[1;33m'
export COLOR_GRAY='\e[0;30m'
export COLOR_LIGHT_GRAY='\e[0;37m'

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
    echo -e "${COLOR_LIGHT_BLUE}${message}${COLOR_NC}"
  fi
}

function logger.info {
  local message="$@"
  if logger.__should-print 'INFO'; then
    echo -e "${COLOR_GREEN}${message}${COLOR_NC}"
  fi
}

function logger.warn {
  local message="$@"
  if logger.__should-print 'WARN'; then
    echo -e "${COLOR_YELLOW}${message}${COLOR_NC}"
  fi
}

function logger.error {
  local message="$@"
  if logger.__should-print 'ERROR'; then
    echo -e "${COLOR_RED}${message}${COLOR_NC}"
  fi
}
