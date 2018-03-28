#!/usr/bin/env bash

include logger.bash
include facter.bash
include exec/package.bash
include exec/executor.bash

function initrd.install-dependencies {
  logger.info ">> Installing tools to Initramfs image"
  local tools lvm fstype busybox_tools tempdir

  tools='partprobe partx parted'
  busybox_tools='comm awk sed sort touch'
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
  if initrd.is-tool-present 'busybox'; then
    tempdir=$(facter.get initrd_tempdir)
    local busybox_supported_tools
    busybox_supported_tools="$(${tempdir}/bin/busybox --list)"
    for tool in $(echo ${busybox_tools}); do
      if ! echo "${busybox_supported_tools}" | grep -q ${tool}; then
        tools="${tools} ${tool}"
      fi
    done
  else
    tools="${tools} ${busybox_tools}"
  fi

  logger.info "Root filesystem type: ${COLOR_CYAN}${fstype}"
  logger.info "Tools to be installed: ${COLOR_CYAN}${tools}"
  # install programs with required libraries
  for tool in $(echo ${tools}); do
    initrd.copy-tool ${tool}
  done
}

function initrd.is-tool-present {
  local tempdir tool initrd_paths tool_present tool_candidate
  tempdir=$(facter.get initrd_tempdir)
  tool="$1"
  initrd_paths=('bin' 'sbin' 'usr/bin' 'usr/sbin')
  logger.debug "Ensure tool: ${tool} is copied to Initramfs image: ${tempdir}"

  tool_present=1
  for bin_path in "${initrd_paths[@]}"; do
    tool_candidate="${tempdir}/${bin_path}/${tool}"
    logger.debug "Checking existance of tool ${tool} in path ${tool_candidate}"
    if [ -x ${tool_candidate} ]; then
      tool_present=0
      break
    fi
  done

  return ${tool_present}
}

function initrd.copy-tool {
  local tool
  tool="$1"

  if initrd.is-tool-present ${tool}; then
    logger.debug "${toolpath} already present in Initramfs image"
  else
    # get tools path
    local toolpath tempdir
    toolpath=$(command -v ${tool})
    # copy tool into initrd
    logger.info "Installing ${COLOR_CYAN}${toolpath}"
    tempdir=$(facter.get initrd_tempdir)
    executor.silently "mkdir -p ${tempdir}/growroot/bin"
    executor.silently "cp -v ${toolpath} ${tempdir}/growroot/bin/${tool}"
    # install needed libraries
    initrd.copy-required-libraries ${toolpath}
  fi
}

function initrd.copy-required-libraries {
  local toolpath tempdir libraries
  toolpath="$1"
  tempdir=$(facter.get initrd_tempdir)

  set +e
  libraries="$(ldd ${toolpath} | grep '\.so' | sed -e '/^[^\t]/ d' | sed -e 's/\t//' | sed -e 's/.*=..//' | sed -e 's/ (0.*)//' | awk 'NF')"
  set -e

  logger.debug "Libraries for tool ${toolpath} are: \n${libraries}"

  if ! [[ "${libraries}-X" == '-X' ]]; then
    local file filename
    for file in ${libraries}; do
      # is this file new?
      filename=$(basename "${file}")
      if [ -f $file ] && [ ! -f ${tempdir}${file} ] && [ ! -f ${tempdir}/growroot/lib/${filename} ]; then
        logger.info "Installing shared library: ${COLOR_CYAN}${file}"
        executor.silently "mkdir -p ${tempdir}/growroot/lib"
        executor.silently "cp -v ${file} ${tempdir}/growroot/lib/${filename}"
      fi
    done
  fi
}
