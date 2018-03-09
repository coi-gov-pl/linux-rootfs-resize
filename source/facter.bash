#!/usr/bin/env bash

include logger.bash

facter_tmpfile=$(mktemp /tmp/lrr.XXXXXX)
trap "{ rm -f $facter_tmpfile; }" EXIT

function facter.set {
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

function facter.get {
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
