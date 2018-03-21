#!/usr/bin/env bash

include facter.bash

function facter.resolve.partition-type {
  local lvm fstype
  lvm=no
  # check if LVM tool lvs is present
  if which lvs 2>&1 >/dev/null; then
    # check for logical volumes
    if [[ "$(LANG=C lvs --noheadings -o +lv_path)" != *No\ volume\ groups\ found* ]]; then
      # get rootfs mount device
      local rootfs_device
      rootfs_device=$(mount | grep -o "^.* / " | awk '{print $1}')
      # look for match, set LVM true if found
      for lv_name in $(lvs --noheading | awk '{print $1}'); do
        [[ "${rootfs_device}" == *${lv_name}* ]] && lvm=yes
      done
    fi
  fi
  facter.set lvm ${lvm}
  fstype=$(LANG=C df -T | grep -E '\s/$' | awk '{print $2}' | sed -e 's:[0-9]::g')
  facter.set fstype ${fstype}
  if ! [[ $fstype == 'ext' ]] && ! [[ $fstype == 'xfs' ]]; then
    logger.error "Filesystem ${fstype} is not supported, supported is only xfs or ext"
    exit 56
  fi
}
facter.resolve.partition-type
