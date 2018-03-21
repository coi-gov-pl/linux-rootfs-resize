#!/usr/bin/env bash

include logger.bash
include facter.bash
include exec/package.bash
include exec/executor.bash

function initrd.install-dependencies {
  logger.info ">> Installing tools to Initramfs image"
  local tools osfamily lvm fstype

  tools='partprobe partx sfdisk sed awk parted tail sort'
  osfamily=$(facter.get osfamily)
  lvm=$(facter.get lvm)
  fstype=$(facter.get fstype)
  if [[ $lvm == 'no' ]]; then
    tools="${tools} growpart"
  fi
  if [[ ${fstype} == 'ext' ]]; then
    tools="${tools} e2fsck resize2fs"
  elif [[ ${fstype} == 'xfs' ]]; then
    tools="${tools} xfs_growfs"
  fi

  logger.info "Root filesystem type: ${COLOR_CYAN}${fstype}"

  logger.debug "Tools to be installed: ${tools}"
  local tempdir
  tempdir=$(facter.get initrd_tempdir)
  # install programs with required libraries
  for tool in $(echo ${tools}); do
    initrd.copy-tool ${tempdir} ${tool}
  done
}

function initrd.copy-tool {
  local tempdir
  tempdir="$1"
  local tool
  tool="$2"
  local initrd_path
  initrd_path='bin sbin usr/bin usr/sbin'

  logger.debug "Ensure tool: ${tool} is copied to Initramfs image: ${tempdir}"

  cd $tempdir

  local tool_present

  tool_present=0
  for bin_path in "${initrd_path}"; do
    [[ -f ${tempdir}${bin_path}/${tool} ]] && tool_present=1
  done
  if [ ${tool_present} -eq 0 ]; then
    # get tools path
    local toolpath
    toolpath=$(command -v ${tool})
    # copy tool into initrd
    logger.info "Installing ${toolpath} into Initramfs image"
    executor.silently "cp -v ${toolpath} ${tempdir}/bin/${tool}"
    # install needed libraries
    initrd.copy-required-libraries ${toolpath}
  else
    logger.debug "${toolpath} already present in Initramfs image"
  fi
}

function initrd.copy-required-libraries {
  local toolpath
  toolpath="$1"
  local tempdir
  tempdir=$(facter.get initrd_tempdir)
  local libraries
  set +e
  libraries="$(ldd ${toolpath} | grep '\.so' | sed -e '/^[^\t]/ d' | sed -e 's/\t//' | sed -e 's/.*=..//' | sed -e 's/ (0.*)//' | awk 'NF')"
  set -e

  logger.debug "Libraries for tool ${toolpath} are: \n${libraries}"

  if ! [[ "${libraries}-X" == '-X' ]]; then
    for file in ${libraries}; do
      # is this file new?
      if [ -f $file ] && [ ! -f ${tempdir}${file} ]; then
        logger.debug "Processing library: ${file}"
        mkdir -p ${tempdir}$(dirname ${file})
        executor.silently "cp -v ${file} ${tempdir}${file}"
      fi
    done
  fi
}
