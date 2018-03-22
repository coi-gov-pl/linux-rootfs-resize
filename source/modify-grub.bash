#!/bin/bash

include logger.bash
include facter.bash
include exec/executor.bash

function modify-grub {
  logger.info '==> Modifing GRUB'

  local grub_version osfamily osfamily_lcase grub_config

  grub_version=$(facter.get grub_version)
  osfamily=$(facter.get osfamily)
  osfamily_lcase=${osfamily,,}

  logger.info "Grub version: ${COLOR_CYAN}${grub_version}"

  grub_config=$(facter.get grub_config)
  logger.info "Grub config: ${COLOR_CYAN}${grub_config}"

  if [[ $grub_version == '2' ]]; then
    modify-grub.modern.${osfamily_lcase} ${grub_config}
  else
    modify-grub.legacy.${osfamily_lcase} ${grub_config}
  fi
}

function modify-grub.modern.redhat {
  local grub_config kernel kernel_growroot
  grub_config="$1"
  kernel=$(facter.get kernel)
  kernel_growroot=$(modify-grub.kernel-growroot-path)

  logger.info "Attaching growrooted Initramfs to GRUB2 for Red Hat family"

  # copy kernel
  if [ ! -f ${kernel_growroot} ]; then
    executor.silently "cp -v ${kernel} ${kernel_growroot}"
  fi
  # generate new grub2 config
  if [ -f /usr/sbin/grub2-mkconfig ]; then
    executor.silently "grub2-mkconfig -o ${grub_config}"
  elif [ -f /usr/sbin/grub-mkconfig ]; then
    executor.silently "grub-mkconfig -o ${grub_config}"
  fi
  # set default
  executor.silently "grubby --set-default ${kernel_growroot}"

  logger.info "Set GRUB to boot by default from: ${COLOR_CYAN}${kernel_growroot}"
}

function modify-grub.legacy.redhat {
  logger.info "Attaching growrooted Initramfs to GRUB Legacy for Red Hat family"

  local grub_config kernel kernel_growroot initrd initrd_growroot
  grub_config="$1"
  kernel=$(facter.get kernel)
  kernel_growroot=$(modify-grub.kernel-growroot-path)
  initrd=$(facter.get initrd)
  initrd_growroot=$(facter.get initrd_growroot)

  # clean existing mod
  executor.silently "grubby -o ${grub_config} --grub --remove-kernel=${kernel_growroot}"
  # create new mod
  # copy kernel
  if [ ! -f ${kernel_growroot} ]; then
    executor.silently "cp -v ${kernel} ${kernel_growroot}"
  fi
  local grub_title grub_kernel grub_initrd
  # grub title
  grub_title="$(facter.get operatingsystem) $(facter.get operatingsystemrelease) $(uname -r) - GrowRootFS"
  # grub kernel (softlink)
  grub_kernel=${kernel_growroot}
  # modified initrd
  grub_initrd=${initrd_growroot}
  # modify grub config
  executor.silently "grubby -o ${grub_config} --grub --copy-default --add-kernel="${grub_kernel}" --title='${grub_title}' --initrd='${grub_initrd}' --make-default"

  logger.info "Set GRUB to boot by default from: ${COLOR_CYAN}${kernel_growroot}"
}

function modify-grub.modern.debian {
  logger.info "Attaching growrooted Initramfs to GRUB2 for Debian family"

  local grub_config kernel kernel_growroot title
  grub_config="$1"
  kernel=$(facter.get kernel)
  kernel_growroot=$(modify-grub.kernel-growroot-path)

  # copy kernel
  if [ ! -f ${kernel_growroot} ]; then
    executor.silently "cp -v ${kernel} ${kernel_growroot}"
  fi
  # generate new grub2 config
  if [ -f /usr/sbin/grub2-mkconfig ]; then
    executor.silently "grub2-mkconfig -o ${grub_config}"
  elif [ -f /usr/sbin/grub-mkconfig ]; then
    executor.silently "grub-mkconfig -o ${grub_config}"
  fi
  # set default
  title=$(awk -F\' '/menuentry / {print $2}' ${grub_config} | grep growroot | head -n 1)
  executor.silently "sed -i -E 's:^GRUB_DEFAULT=0$:GRUB_DEFAULT=saved:' /etc/default/grub"
  executor.silently "grub-set-default '${title}'"

  logger.info "Set GRUB to boot by default from: ${COLOR_CYAN}${kernel_growroot}"
}

function modify-grub.legacy.debian {
  logger.info "Attaching growrooted Initramfs to GRUB Legacy for Debian family"

  logger.error "Not yet implemented"
  exit 133
}

function modify-grub.kernel-growroot-path {
  local kernel kernel_growroot

  kernel=$(facter.get kernel)
  kernel_growroot="${kernel}-growroot"

  echo $kernel_growroot
}
