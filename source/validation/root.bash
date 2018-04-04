#!/bin/bash

include logger.bash

if [[ "${LRR_EXEC:-1}" == 1 ]] && [ "$EUID" -ne 0 ]; then
  logger.error "Please run linux-rootfs-resize ./install script as root"
  exit 2
fi
