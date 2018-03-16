growroot()
{
  set -e
  echo "[] linux-rootfs-resize ..."
  set -x
  local root_part
  root_part=$(echo ${root} | sed "s/block://")
  local root_dev
  root_dev=$(readlink ${root_part} | sed "s/[^a-z]//g")
  local part_num
  part_num=$(readlink ${root_part} | sed "s/[^0-9]//g")

  growpart -v /dev/${root_dev} ${part_num}
  partx -a /dev/${root_dev}
  e2fsck -f /dev/${root_dev}${part_num}
  resize2fs -p /dev/${root_dev}${part_num}
  set +x
}
