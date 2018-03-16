growroot()
{
  set -e
  echo "[] linux-rootfs-resize ..."
  set -x
  local root_dev
  root_dev=$(readlink ${ROOT} | sed "s/[^a-z]//g")
  local part_num
  part_num=$(readlink ${ROOT} | sed "s/[^0-9]//g")

  growpart -v /dev/${root_dev} ${part_num}
  e2fsck -p -f /dev/${root_dev}${part_num}
  resize2fs -p /dev/${root_dev}${part_num}
  set +x
}
