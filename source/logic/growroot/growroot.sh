growroot()
{
  set -eo pipefail
  echo "[] linux-rootfs-resize ..."
  set -x

  . /etc/lrr.conf

  local cmd_root root_part root_dev part_num threshhold
  local uuid label root_dev_temp

  threshhold='100' # min. 100 MiB
  cmd_root=$(cat /proc/cmdline | sed -E 's:.*root=([^ ]+).*:\1:g')
  if echo "${cmd_root}" | grep -q 'UUID='; then
    uuid=$(echo "${cmd_root}" | sed -E 's:UUID=(.+):\1:g')
    root_part=$(readlink -f /dev/disk/by-uuid/${uuid})
  elif echo "${cmd_root}" | grep -q 'LABEL='; then
    label=$(echo "${cmd_root}" | sed -E 's:LABEL=(.+):\1:g')
    root_part=$(readlink -f /dev/disk/by-label/${label})
  else
    root_part=$(readlink -f ${cmd_root})
  fi
  root_dev_temp=$(echo ${root_part} | sed 's:/dev/::')
  root_dev=$(echo ${root_dev_temp} | sed "s/[^a-z]//g")
  part_num=$(echo ${root_dev_temp} | sed "s/[^0-9]//g")

  freespace=$(parted /dev/${root_dev} unit MB print free | awk '/Free Space/{c++; sum += $3} END{if(c == 0) print 0; else print sum}')

  if [[ "$freespace" -gt $threshhold ]]; then
    growpart -v /dev/${root_dev} ${part_num}
    partx -a /dev/${root_dev}

    if [ "${LRR_FSTYPE}-X" = 'ext-X' ]; then
      e2fsck -p -f /dev/${root_dev}${part_num}
      resize2fs -p /dev/${root_dev}${part_num}
    elif [ "${LRR_FSTYPE}-X" = 'xfs-X' ]; then
      mkdir -p /mnt/rootfs
      mount /dev/${root_dev}${part_num} /mnt/rootfs
      xfs_growfs /dev/${root_dev}${part_num}
      umount /mnt/rootfs
    fi
  fi

  set +x

  return 0
}