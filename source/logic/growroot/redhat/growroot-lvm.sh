growroot()
{
  set -eo pipefail
  echo "[] linux-rootfs-resize ..."
  set -x

  local lvm_lv_root lvm_pv_path lvm_pv_temp lvm_pv_dev lvm_pv_part freespace threshhold

  threshhold='104857600' # min. 100 MiB
  lvm_lv_root=$(echo ${root} | sed "s/block://")
  lvm_pv_path=$(lvm pvs --noheadings | awk '{print $1}')
  lvm_pv_temp=$(echo ${lvm_pv_path} | sed "s/\/dev\///")
  lvm_pv_dev=$(echo ${lvm_pv_temp} | sed "s/[^a-z]//g")
  lvm_pv_part=$(echo ${lvm_pv_temp} | sed "s/[^0-9]//g")

  freespace=$(parted /dev/${lvm_pv_dev} unit B print free | awk '/Free Space/{c++; sum += $3} END{if(c == 0) print 0; else print sum}')

  if [[ "$freespace" -gt $threshhold ]]; then
    lvm vgchange --sysinit -an
    growpart -v /dev/${lvm_pv_dev} ${lvm_pv_part}
    partprobe -s /dev/${lvm_pv_dev}
    lvm pvresize -v ${lvm_pv_path}
    lvm vgchange --sysinit -ay
    lvm lvextend -v -l +100%FREE ${lvm_lv_root}
    e2fsck -p -f ${lvm_lv_root}
    resize2fs -p ${lvm_lv_root}
    lvm vgchange --sysinit -ay
  fi

  set +x

  return 0
}
