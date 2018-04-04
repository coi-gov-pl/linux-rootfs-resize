#!/bin/bash

include logger.bash
include facter.bash
include logic/modify/initrd/unpack.bash
include logic/modify/initrd/install-dependencies.bash
include logic/modify/initrd/modify-init.bash
include logic/modify/initrd/repack.bash

function modify-initrd {
  logger.info '==> Modifing Initrd'

  initrd.unpack
  initrd.install-dependencies
  initrd.modify-init
  initrd.repack
}
