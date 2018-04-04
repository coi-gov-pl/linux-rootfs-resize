#!/usr/bin/env bash

include logger.bash
include facter/bash.bash

if (( $BASH_MAJOR_VERSION >= 5 )) || (( $BASH_MINOR_VERSION >= 2 )); then
  declare -gA __facter_facts
fi
export __facter_facts_names
__facter_facts_names=()

function facter.set {
  if (( $BASH_MAJOR_VERSION >= 5 )) || (( $BASH_MINOR_VERSION >= 2 )); then
    facter.modern.set $1 $2
  else
    facter.legacy.set $1 $2
  fi
}

function facter.get {
  if (( $BASH_MAJOR_VERSION >= 5 )) || (( $BASH_MINOR_VERSION >= 2 )); then
    facter.modern.get $1
  else
    facter.legacy.get $1
  fi
}

function facter.modern.set {
  local key
  key="$1"
  local value
  value="$2"
  __facter_facts[$key]="${value}"
  __facter_facts_names+=($key)
}

function facter.modern.get {
  local key
  key="$1"
  local value
  value=${__facter_facts[$key]}
  if [[ "${value}-X" == "-X" ]]; then
    logger.error "Fact ${key} is not known!"
    exit 166
  fi
  echo "${value}"
}

function facter.legacy.set {
  local key="$1"
  local value="$2"

  eval "export __facter_facts_${key} && __facter_facts_${key}='${value}'"
  __facter_facts_names+=($key)
}

function facter.legacy.get {
  local key
  key="$1"
  local fact_value_name
  fact_value_name="__facter_facts_${key}"

  local value

  value="${!fact_value_name}"
  if [[ "${value}-X" == "-X" ]]; then
    logger.error "Fact ${key} is not known!"
    exit 166
  fi
  echo "${value}"
}

function facter.list.known {
  echo "${__facter_facts_names[@]}"
}

include facter/os.bash
include facter/kernel.bash
include facter/grub.bash
include facter/partition-type.bash
include facter/initrd-type.bash
