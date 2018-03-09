#!/usr/bin/env bash

include logger.bash

function view.farewell {
  logger.success ''
  logger.success 'Everything went fine! Please reboot machine to resize root partition!'
  logger.success 'Happy linuxing :-)'
}
