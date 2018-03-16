growroot()
{
  set -e
  echo "[] linux-rootfs-resize ..."
  set -x
  lvm vgchange -an
  local lvm_pv_path=$(lvm pvs --noheadings |awk '{print $1}')
  local lvm_pv_temp=$(echo ${lvm_pv_path}|sed "s/dev//g")
  local lvm_pv_dev=$(echo ${lvm_pv_temp}| sed "s/[^a-z]//g")
  local lvm_pv_part=$(echo ${lvm_pv_temp}| sed "s/[^0-9]//g")

  growpart -v /dev/${lvm_pv_dev} ${lvm_pv_part}
  lvm pvresize -v ${lvm_pv_path}
  lvm vgchange --sysinit -ay
  lvm lvresize -v -l +100%FREE ${ROOT}
  e2fsck -p -f ${ROOT}
  resize2fs -p ${ROOT}
  set +x
}
