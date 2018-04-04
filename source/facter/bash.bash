#!/usr/bin/env bash

export BASH_VERSION=$(LANG=C bash --version | grep 'GNU bash' | awk '{print $4}')
export BASH_MAJOR_VERSION=$(echo ${BASH_VERSION} | cut -d '.' -f 1)
export BASH_MINOR_VERSION=$(echo ${BASH_VERSION} | cut -d '.' -f 2)
