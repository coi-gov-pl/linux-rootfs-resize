#!/usr/bin/env bash

include facter.bash

function facter.resolve.partition-type {
  local lvm
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
}
facter.resolve.partition-type
