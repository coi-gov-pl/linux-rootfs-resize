#!/bin/sh

if [ ! -f /etc/lrr.conf ]; then
  echo '/etc/lrr.conf file is required' 1>&2
  exit 144
fi

. /etc/lrr.conf

facter_get() {
  local key fact_value_name value
  key="$1"
  fact_value_name="LRR_FACT_${key}"
  eval "value=\${${fact_value_name}}"
  if [ "${value}-X" = "-X" ]; then
    echo "Fact ${key} is not known!" 1>&2
    exit 166
  fi
  echo "${value}"
}

array_contains() {
  local e match
  match="$1"
  shift
  for e in $(echo "$@"); do
    [ "$e" = "$match" ] && return 0
  done
  return 1
}

exitcodes() {
  local exitstatus fact acceptable fact_value
  exitstatus="$1"
  fact="$2"
  shift 2
  acceptable="$*"
  fact_value=$(facter_get $fact)
  if ! [ "${fact_value}-X" = "true-X" ] && ! [ "${fact_value}-X" = "yes-X" ]; then
    acceptable='0'
  fi
  if ! array_contains $exitstatus "0 ${acceptable}"; then
    return $exitstatus
  fi
  return 0
}
