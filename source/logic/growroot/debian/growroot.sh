growroot()
{
  set -e
  echo "[] linux-rootfs-resize ..."
  root_dev=$(readlink ${ROOT} | sed "s/[^a-z]//g")
  part_num=$(readlink ${ROOT} | sed "s/[^0-9]//g")
  growpart -v /dev/${root_dev} ${part_num}
  e2fsck -p -f /dev/${root_dev}${part_num}
  resize2fs -p /dev/${root_dev}${part_num}
}
