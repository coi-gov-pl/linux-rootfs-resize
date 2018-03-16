growroot()
{
  set -eo pipefail
  echo "[] linux-rootfs-resize ..."
  set -x
  local root_dev part_num threshhold

  threshhold='104857600' # min. 100 MiB

  root_dev=$(readlink ${ROOT} | sed "s/[^a-z]//g")
  part_num=$(readlink ${ROOT} | sed "s/[^0-9]//g")

  freespace=$(parted /dev/${root_dev} unit B print free | awk '/Free Space/{c++; sum += $3} END{if(c == 0) print 0; else print sum}')

  if [[ "$freespace" -gt $threshhold ]]; then
    growpart -v /dev/${root_dev} ${part_num}
    e2fsck -p -f /dev/${root_dev}${part_num}
    resize2fs -p /dev/${root_dev}${part_num}
  fi
  set +x

  return 0
}
