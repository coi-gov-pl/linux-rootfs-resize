#!/usr/bin/env bash

include logger.bash
include facter.bash
include exec/executor.bash

function initrd.modify-init {
  logger.info ">> Modifing init stript in Initramfs image"

  local initrd_init_type sourcefile partition_management

  initrd_init_type=$(facter.get initrd_init_type)
  partition_management=$(facter.get partition_management)
  logger.info "Initramfs init type: ${COLOR_CYAN}${initrd_init_type}"
  logger.info "Partition management: ${COLOR_CYAN}${partition_management}"

  if [[ $partition_management == 'lvm' ]]; then
    sourcefile="${REPODIR}/source/logic/growroot/growroot-lvm.sh"
  else
    sourcefile="${REPODIR}/source/logic/growroot/growroot.sh"
  fi

  initrd.modify-init.prerequisites
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

  logger.info "Initramfs was modified successfully with script: ${COLOR_CYAN}${sourcefile}"
}

function initrd.modify-init.systemd {
  local initrd_tempdir sourcefile targethook

  initrd_tempdir=$(facter.get initrd_tempdir)
  sourcefile="$1"
  targethook="${initrd_tempdir}/lib/dracut/hooks/pre-mount/growroot.sh"

  executor.silently "cp -v ${sourcefile} ${targethook}"
  executor.silently "echo 'growroot' >> ${targethook}"
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
  local procname init_script sourcefile proc_insert_point call_insert_point tempfile

  procname='growroot'
  init_script="$1"
  sourcefile="$2"
  proc_insert_point="$3"
  call_insert_point="$4"

  tempfile=$(mktemp -t growroot-source.XXXXXX)
  # shellcheck disable=SC2064
  trap "executor.silently 'rm -fv ${tempfile}'" EXIT

  executor.silently "cat ${sourcefile} | sed -e 's:#!/.*::' > ${tempfile}"

  if ! grep -qE "^${procname}\(\)$" "${init_script}"; then
    if ! grep -qE "${proc_insert_point}" "${init_script}"; then
      logger.error "Function insert point: '${proc_insert_point}' is not found in init script: ${init_script}"
      exit 24
    fi
    executor.silently "sed -i.1 -e '/${proc_insert_point}/r ${tempfile}' -e '//N' ${init_script}"
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

function initrd.modify-init.prerequisites {
  local lvm initrd_tempdir growrootlib fact fact_value
  lvm=$(facter.get lvm)
  initrd_tempdir=$(facter.get initrd_tempdir)
  executor.silently 'touch etc/mtab'
  if [ "${lvm}" == "yes" ]; then
    executor.silently "sed -i 's/locking_type = 4/locking_type = 1/' ${initrd_tempdir}/etc/lvm/lvm.conf"
  fi

  executor.silently "mkdir -p ${initrd_tempdir}/etc"
  executor.silently "echo '' > ${initrd_tempdir}/etc/lrr.conf"
  for fact in $(facter.list.known); do
    fact_value=$(facter.get ${fact})
    executor.silently "echo 'local LRR_FACT_${fact}=${fact_value}' >> ${initrd_tempdir}/etc/lrr.conf"
  done
  growrootlib="${REPODIR}/source/logic/growroot/lib.sh"
  executor.silently "cp -v ${growrootlib} ${initrd_tempdir}/lib/growroot-lib.sh"
}
