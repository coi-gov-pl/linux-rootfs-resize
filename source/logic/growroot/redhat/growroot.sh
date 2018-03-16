growroot()
{
  set -eo pipefail
  echo "[] linux-rootfs-resize ..."
  set -x
  local root_part root_dev part_num threshhold

  threshhold='104857600' # min. 100 MiB
  root_part=$(echo ${root} | sed "s/block://")
  root_dev=$(readlink ${root_part} | sed "s/[^a-z]//g")
  part_num=$(readlink ${root_part} | sed "s/[^0-9]//g")

  freespace=$(parted /dev/${root_dev} unit B print free | awk '/Free Space/{c++; sum += $3} END{if(c == 0) print 0; else print sum}')

  if [[ "$freespace" -gt $threshhold ]]; then
    growpart -v /dev/${root_dev} ${part_num}
    partx -a /dev/${root_dev}
    e2fsck -f /dev/${root_dev}${part_num}
    resize2fs -p /dev/${root_dev}${part_num}
  fi

  set +x

  return 0
}
