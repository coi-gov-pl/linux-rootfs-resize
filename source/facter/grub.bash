#!/usr/bin/env bash

include facter.bash
include lang/version.bash

function facter.resolve.grub {
  local grub_version
  if command -v grub2-install > /dev/null; then
    grub_version=2
  else
    local grub_version_plain
    grub_version_plain=$(grub-install --version)
    # https://regex101.com/r/pCr7wE/3
    grub_version_plain=$(echo "${grub_version_plain}" | sed -E 's/.+GRUB[^0-9]+([0-9\.]+).+/\1/')
    local grub2_match=$(version.match ${grub_version_plain} gt 1.8)
    if [[ $grub2_match == 'true' ]]; then
      grub_version=2
    else
      grub_version=1
    fi
  fi
  facter.set grub_version ${grub_version}

  facter.resolve.grub-config
}

function facter.resolve.grub-config {
  local candidates=(
    '/boot/grub2/grub.cfg'
    '/boot/grub/grub.cfg'
    '/boot/grub/grub.conf'
  )
  for candidate in ${candidates[@]}; do
    if [ -f $candidate ]; then
      facter.set grub_config ${candidate}
      break
    fi
  done
}

facter.resolve.grub
