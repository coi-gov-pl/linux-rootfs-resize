#!/bin/sh
growroot()
{
  local state path_saved ldpath_saved
  state=$(set +o)

  if echo "${state}" | grep -q pipefail; then
    set -o pipefail
  fi
  set -e
  . /lib/growroot-lib.sh
  echo "[] linux-rootfs-resize ..."
  set -x

  path_saved="${PATH}"
  ldpath_saved="${LD_LIBRARY_PATH}"
  export PATH="/growroot/bin:${PATH}"
  export LD_LIBRARY_PATH="/growroot/lib:${LD_LIBRARY_PATH}"

  local cmd_root uuid label
  local lvm_lv_root lvm_pv_path lvm_pv_temp lvm_pv_dev freespace threshhold lvm_pv_newpart lvm_vg

  threshhold=100
  cmd_root=$(cat /proc/cmdline | sed -r 's:.*root=([^ ]+).*:\1:g')
  if echo "${cmd_root}" | grep -q 'UUID='; then
    uuid=$(echo "${cmd_root}" | sed -r 's:UUID=(.+):\1:g')
    lvm_lv_root=$(readlink -f /dev/disk/by-uuid/${uuid})
  elif echo "${cmd_root}" | grep -q 'LABEL='; then
    label=$(echo "${cmd_root}" | sed -r 's:LABEL=(.+):\1:g')
    lvm_lv_root=$(readlink -f /dev/disk/by-label/${label})
  else
    lvm_lv_root=${cmd_root}
  fi

  lvm_pv_path=$(LANG=C lvm pvs --noheadings | awk '{print $1}')
  lvm_vg=$(LANG=C lvm pvs --noheadings | awk '{print $2}')
  lvm_pv_temp=$(echo ${lvm_pv_path} | sed 's:/dev/::')
  lvm_pv_dev=$(echo ${lvm_pv_temp} | sed 's/[^a-z]//g')

  freespace=$(LANG=C parted /dev/${lvm_pv_dev} unit MB print free | awk 'BEGIN { sum = 0 } /Free Space/ { sum += int($3)} END { print sum }')

  # Try to extend partition if there is min. 100 MiB free space
  if [ "$freespace" -gt $threshhold ]; then
    local start_end start end fstype kernel_legacy
    start_end=$(LANG=C parted /dev/${lvm_pv_dev} unit MB print free | awk 'BEGIN {found = 0; start = 0; end = 0} /Free Space/ {actual = int($3); if (actual > found) { found = actual; start = int($1); end = int($2) } } END { print start, end }')
    start=$(echo "${start_end}" | awk '{print $1}')
    end=$(echo "${start_end}" | awk '{print $2}')
    kernel_legacy=$(facter_get kernel_legacy)

    ls /dev/${lvm_pv_dev}[0-9]* | sort > /tmp/partitions.before
    # Create new partition at end of the disk
    if [ "${kernel_legacy}" = 'true' ]; then
      lvm vgchange --sysinit -an
      sleep 3
    fi
    parted -a optimal -s /dev/${lvm_pv_dev} "mkpart primary ext4 ${start} ${end}"
    # Notify kernel of newly created partitions
    partprobe -s /dev/${lvm_pv_dev}
    ls /dev/${lvm_pv_dev}[0-9]* | sort > /tmp/partitions.after

    lvm_pv_newpart=$(comm -13 /tmp/partitions.before /tmp/partitions.after)
    lvm_pv_newpart=$(echo "${lvm_pv_newpart}" | sed 's:[^0-9]::g')
    # Create new PV
    lvm pvcreate -v /dev/${lvm_pv_dev}${lvm_pv_newpart}
    # Extend VG with newly created PV
    lvm vgextend -v /dev/${lvm_vg} /dev/${lvm_pv_dev}${lvm_pv_newpart}

    # Extend LV to 100% free space
    lvm lvextend -v -l +100%FREE ${lvm_lv_root}

    if [ ! -f ${lvm_lv_root} ]; then
      lvm vgchange --sysinit -ay
    fi
    fstype=$(facter_get fstype)
    if [ "${fstype}-X" = 'ext-X' ]; then
      # Grow root EXT partition
      touch /etc/mtab
      e2fsck -p -f ${lvm_lv_root}
      resize2fs -p ${lvm_lv_root}
    elif [ "${fstype}-X" = 'xfs-X' ]; then
      # Grow root XFS partition
      mkdir -p /mnt/rootfs
      mount ${lvm_lv_root} /mnt/rootfs
      xfs_growfs ${lvm_lv_root}
      umount /mnt/rootfs
    fi
  fi

  echo "[*] linux-rootfs-resize - DONE"

  set +x
  export PATH="${path_saved}"
  export LD_LIBRARY_PATH="${ldpath_saved}"
  eval "${state}"

  return 0
}
