#!/usr/bin/env bash

include facter.bash

function facter.resolve.partition-type {
  local lvm fstype rootfs_device partition_management
  # get rootfs mount device
  rootfs_device=$(mount | grep -o "^.* / " | awk '{print $1}')
  lvm=no
  partition_management='partition-table'
  # check if LVM tool lvs is present
  if which lvs >/dev/null 2>&1; then
    # check for logical volumes
    if [[ "$(LANG=C lvs --noheadings -o +lv_path)" != *No\ volume\ groups\ found* ]]; then
      # look for match, set LVM true if found
      for lv_name in $(LANG=C lvs --noheading | awk '{print $1}'); do
        [[ "${rootfs_device}" == *${lv_name}* ]] && lvm=yes
      done
    fi
  fi
  facter.set lvm ${lvm}
  [[ ${lvm} == 'yes' ]] && partition_management='lvm'
  facter.set partition_management ${partition_management}
  # Grep multiline and sed removes new line - when df returns newline after volume name
  fstype=$(LANG=C df -T | grep -Pzo "${rootfs_device}\n?\s+[^\s]+" | sed ':a;N;$!ba;s/\n/ /g' | awk '{print $2}' | sed -e 's:[0-9]::g')
  facter.set fstype ${fstype}
  if ! [[ $fstype == 'ext' ]] && ! [[ $fstype == 'xfs' ]]; then
    logger.error "Filesystem ${fstype} is not supported, supported is only xfs or ext"
    exit 56
  fi
}
facter.resolve.partition-type
