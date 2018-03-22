growroot()
{
  local state
  state=$(set +o)

  set -o pipefail
  set -e
  echo "[] linux-rootfs-resize ..."
  set -x

  . /etc/lrr.conf

  local cmd_root
  local lvm_lv_root lvm_pv_path lvm_pv_temp lvm_pv_dev lvm_pv_part freespace threshhold lvm_pv_newpart lvm_vg

  threshhold=100
  cmd_root=$(cat /proc/cmdline | sed -E 's:.*root=([^ ]+).*:\1:g')
  if echo "${cmd_root}" | grep -q 'UUID='; then
    local uuid=$(echo "${cmd_root}" | sed -E 's:UUID=(.+):\1:g')
    lvm_lv_root=$(readlink -f /dev/disk/by-uuid/${uuid})
  elif echo "${cmd_root}" | grep -q 'LABEL='; then
    local label=$(echo "${cmd_root}" | sed -E 's:LABEL=(.+):\1:g')
    lvm_lv_root=$(readlink -f /dev/disk/by-label/${label})
  else
    lvm_lv_root=${cmd_root}
  fi

  lvm_pv_path=$(LANG=C lvm pvs --noheadings | awk '{print $1}')
  lvm_vg=$(LANG=C lvm pvs --noheadings | awk '{print $2}')
  lvm_pv_temp=$(echo ${lvm_pv_path} | sed 's:/dev/::')
  lvm_pv_dev=$(echo ${lvm_pv_temp} | sed 's/[^a-z]//g')
  lvm_pv_part=$(echo ${lvm_pv_temp} | sed 's/[^0-9]//g')

  freespace=$(LANG=C parted /dev/${lvm_pv_dev} unit MB print free | awk '/Free Space/{c++; sum += int($3)} END{if(c == 0) print 0; else print sum}')

  # Try to extend partition if there is min. 100 MiB free space
  if [ "$freespace" -gt $threshhold ]; then
    local start
    start=$(LANG=C parted /dev/${lvm_pv_dev} unit MB print free | awk 'BEGIN {found = 0; start = 0} /Free Space/ {actual = int($3); if (actual > found) { found = actual; start = int($1) } } END { print start }')

    ls /dev/${lvm_pv_dev}[0-9]* | sort > /tmp/partitions.before
    # Create new partition at end of the disk
    parted -a optimal -s /dev/${lvm_pv_dev} "mkpart primary ext4 ${start} -0"
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

    if [ "${LRR_FSTYPE}-X" = 'ext-X' ]; then
      # Grow root EXT partition
      e2fsck -p -f ${lvm_lv_root}
      resize2fs -p ${lvm_lv_root}
    elif [ "${LRR_FSTYPE}-X" = 'xfs-X' ]; then
      # Grow root XFS partition
      mkdir -p /mnt/rootfs
      mount ${lvm_lv_root} /mnt/rootfs
      xfs_growfs ${lvm_lv_root}
      umount /mnt/rootfs
    fi
  fi

  echo "[*] linux-rootfs-resize - DONE"

  set +x
  eval "${state}"

  return 0
}
