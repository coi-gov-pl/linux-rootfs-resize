#!/usr/bin/env bash

include logger.bash
include facter.bash
include exec/executor.bash

function initrd.modify-init {
  logger.info ">> Modifing init stript in Initramfs image"

  local lvm osfamily initrd_init_type osfamily_lcase classifier sourcefile

  lvm=$(facter.get lvm)
  osfamily=$(facter.get osfamily)
  initrd_init_type=$(facter.get initrd_init_type)
  logger.info "Initramfs init type: ${COLOR_CYAN}${initrd_init_type}"
  logger.info "Does rootfs uses LVM: ${COLOR_CYAN}${lvm}"

  osfamily_lcase="${osfamily,,}"
  classifier=''
  if [[ $lvm == 'yes' ]]; then
    classifier="$classifier-lvm"
  fi
  sourcefile="${REPODIR}/source/logic/growroot/${osfamily_lcase}/growroot${classifier}.sh"

  case $initrd_init_type in
    systemd)
      initrd.modify-init.systemd "${sourcefile}"
      ;;
    systemv-plain-init)
      initrd.modify-init.systemv-plain-init "${sourcefile}"
      ;;
    systemv-scripts-local)
      initrd.modify-init.systemv-scripts-local "${sourcefile}"
      ;;
  esac

  logger.info "Initramfs was modified successfully with classifier: ${COLOR_CYAN}${classifier}"
}

function initrd.modify-init.systemd {
  local initrd_tempdir
  initrd_tempdir=$(facter.get initrd_tempdir)
  local sourcefile
  sourcefile="$1"
  local targethook
  targethook="${initrd_tempdir}/lib/dracut/hooks/pre-mount/growroot.sh"
  local shebang
  shebang="${REPODIR}/source/logic/growroot/shebang.sh"
  local invoke
  invoke="${REPODIR}/source/logic/growroot/invoke.sh"
  local scripts
  scripts=(
    '/tmp/growroot-shebang.sh'
    '/tmp/growroot-function.sh'
    '/tmp/growroot-invoke.sh'
  )

  executor.silently "cp -v ${shebang} /tmp/growroot-shebang.sh"
  executor.silently "cp -v ${sourcefile} /tmp/growroot-function.sh"
  executor.silently "cp -v ${invoke} /tmp/growroot-invoke.sh"

  executor.silently "cat ${scripts[@]} > ${targethook}"
  executor.silently "chmod +x ${targethook}"

  logger.info "Creaded Dracut pre-mount hook: ${COLOR_CYAN}${targethook}"
}

function initrd.modify-init.systemv-plain-init {
  local initrd_tempdir
  initrd_tempdir=$(facter.get initrd_tempdir)
  local init_script
  init_script="${initrd_tempdir}/init"
  local sourcefile
  sourcefile="$1"
  local proc_insert_point
  proc_insert_point='^export PATH=.*'
  local call_insert_point
  call_insert_point='^source_all pre-mount'

  initrd.modify-init.systemv "${init_script}" "${sourcefile}" "${proc_insert_point}" "${call_insert_point}"
}

function initrd.modify-init.systemv-scripts-local {
  local initrd_tempdir
  initrd_tempdir=$(facter.get initrd_tempdir)
  local init_script
  init_script="${initrd_tempdir}/scripts/local"
  local sourcefile
  sourcefile="$1"
  local proc_insert_point
  proc_insert_point='^mountroot()'
  local call_insert_point
  call_insert_point='^.*\(pre_mountroot\|local_mount_root\)$'

  initrd.modify-init.systemv "${init_script}" "${sourcefile}" "${proc_insert_point}" "${call_insert_point}"
}

function initrd.modify-init.systemv {
  local procname
  procname='growroot'
  local init_script
  init_script="$1"
  local sourcefile
  sourcefile="$2"
  local proc_insert_point
  proc_insert_point="$3"
  local call_insert_point
  call_insert_point="$4"

  initrd.modify-init.systemv-prerequisites
  if ! grep -qE "^${procname}\(\)$" "${init_script}"; then
    if ! grep -qE "${proc_insert_point}" "${init_script}"; then
      logger.error "Function insert point: '${proc_insert_point}' is not found in init script: ${init_script}"
      exit 24
    fi
    executor.silently "sed -i.1 -e '/${proc_insert_point}/r ${sourcefile}' -e '//N' ${init_script}"
    if diff "${init_script}.1" "${init_script}" >/dev/null; then
      logger.error "There must be error, init is not modified!"
      exit 25
    fi
    executor.silently "rm -fv '${init_script}.1'"
  else
    logger.debug "Function '${procname}' already present in init file ${init_script}"
  fi
  if ! grep -qE "^${procname}$" "${init_script}"; then
    if ! grep -q "${call_insert_point}" "${init_script}"; then
      logger.error "Function invokation insert point: '${call_insert_point}' is not found in init script: ${init_script}"
      exit 24
    fi
    executor.silently "sed -i.2 '/${call_insert_point}/i ${procname}' ${init_script}"
    if diff "${init_script}.2" "${init_script}" >/dev/null; then
      logger.error "There must be error, init is not modified!"
      exit 25
    fi
    executor.silently "rm -fv '${init_script}.2'"
  else
    logger.debug "Function invokation '${procname}' already present in init file ${init_script}"
  fi

  logger.info "Successfully patched Initramfs init script, by adding growroot procedure: ${COLOR_CYAN}${init_script}"
}

function initrd.modify-init.systemv-prerequisites {
  local lvm
  lvm=$(facter.get lvm)
  local initrd_tempdir
  initrd_tempdir=$(facter.get initrd_tempdir)
  executor.silently 'touch etc/mtab'
  if [ "${lvm}" == "yes" ]; then
    executor.silently "sed -i 's/locking_type = 4/locking_type = 1/' ${initrd_tempdir}/etc/lvm/lvm.conf"
  fi
}
