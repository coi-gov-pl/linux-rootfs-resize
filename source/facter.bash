#!/usr/bin/env bash

include logger.bash
include facter/bash.bash

if (( $BASH_MAJOR_VERSION >= 5 )) || (( $BASH_MINOR_VERSION >= 2 )); then
  declare -gA __facter_facts
else
  facter_tmpfile=$(mktemp /tmp/lrr.XXXXXX)
  trap "{ rm -f $facter_tmpfile; }" EXIT
fi

function facter.set {
  if (( $BASH_MAJOR_VERSION >= 5 )) || (( $BASH_MINOR_VERSION >= 2 )); then
    facter.modern.set $@
  else
    facter.legacy.set $@
  fi
}

function facter.get {
  if (( $BASH_MAJOR_VERSION >= 5 )) || (( $BASH_MINOR_VERSION >= 2 )); then
    facter.modern.get $@
  else
    facter.legacy.get $@
  fi
}

function facter.modern.set {
  local key="$1"
  local value="$2"
  __facter_facts[$key]="${value}"
}

function facter.modern.get {
  local key="$1"
  local value=${__facter_facts[$key]}
  if [[ "${value}-X" == "-X" ]]; then
    logger.warn "Fact ${key} is not known!"
  fi
  echo "${value}"
}

function facter.legacy.set {
  local key="$1"
  local value="$2"
  local facts_serialized="$(cat $facter_tmpfile)"
  declare -A facts
  if ! [[ "${facts_serialized}-X" == "-X" ]]; then
    eval "${facts_serialized}"
  fi
  facts[$key]="${value}"
  facts_serialized="$(declare -p facts)"
  echo $facts_serialized > $facter_tmpfile
}

function facter.legacy.get {
  local key="$1"
  local facts_serialized="$(cat $facter_tmpfile)"
  declare -A facts
  if ! [[ "${facts_serialized}-X" == "-X" ]]; then
    eval "${facts_serialized}"
  fi
  local value=${facts[$key]}
  if [[ "${value}-X" == "-X" ]]; then
    logger.warn "Fact ${key} is not known!"
  fi
  echo "${value}"
}

include facter/os.bash
