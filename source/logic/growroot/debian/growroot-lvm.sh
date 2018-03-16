growroot()
{
  set -eo pipefail
  echo "[] linux-rootfs-resize ..."
  set -x
  local lvm_pv_path lvm_pv_temp lvm_pv_dev lvm_pv_part threshhold

  threshhold='104857600' # min. 100 MiB

  lvm_pv_path=$(lvm pvs --noheadings | awk '{print $1}')
  lvm_pv_temp=$(echo ${lvm_pv_path} | sed "s/\/dev\///")
  lvm_pv_dev=$(echo ${lvm_pv_temp} | sed "s/[^a-z]//g")
  lvm_pv_part=$(echo ${lvm_pv_temp} | sed "s/[^0-9]//g")

  freespace=$(parted /dev/${lvm_pv_dev} unit B print free | awk '/Free Space/{c++; sum += $3} END{if(c == 0) print 0; else print sum}')

  if [[ "$freespace" -gt $threshhold ]]; then
    lvm vgchange --sysinit -an
    growpart -v /dev/${lvm_pv_dev} ${lvm_pv_part}
    lvm pvresize -v ${lvm_pv_path}
    lvm vgchange --sysinit -ay
    lvm lvresize -v -l +100%FREE ${ROOT}
    e2fsck -p -f ${ROOT}
    resize2fs -p ${ROOT}
    lvm vgchange --sysinit -ay
  fi

  set +x

  return 0
}
