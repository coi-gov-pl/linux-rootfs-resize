growroot()
{
  set -e
  echo "[] linux-rootfs-resize ..."
  set -x
  lvm vgchange --sysinit -an
  local lvm_lv_root
  lvm_lv_root=$(echo ${root} |sed "s/block://")
  local lvm_pv_path
  lvm_pv_path=$(lvm pvs --noheadings |awk '{print $1}')
  local lvm_pv_temp
  lvm_pv_temp=$(echo ${lvm_pv_path}|sed "s/dev//g")
  local lvm_pv_dev
  lvm_pv_dev=$(echo ${lvm_pv_temp}| sed "s/[^a-z]//g")
  local lvm_pv_part
  lvm_pv_part=$(echo ${lvm_pv_temp}| sed "s/[^0-9]//g")

  growpart -v /dev/${lvm_pv_dev} ${lvm_pv_part}
  partprobe -s /dev/${lvm_pv_dev}
  lvm pvresize -v ${lvm_pv_path}
  lvm vgchange --sysinit -ay
  lvm lvextend -v -l +100%FREE ${lvm_lv_root}
  e2fsck -p -f ${lvm_lv_root}
  resize2fs -p ${lvm_lv_root}
  set +x
}
