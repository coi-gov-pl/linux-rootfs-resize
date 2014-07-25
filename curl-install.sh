#!/bin/bash
#

function get_distro() {
  distro=""
  [ -f /etc/redhat-release ] &&
    if [[ "$(cat /etc/redhat-release)" == *CentOS\ release\ 6* ]]; then
      distro="centos-6"
    fi
  [ -f /etc/issue ] &&
    if [[ "$(cat /etc/issue)" == *Debian* ]]; then
      distro="debian"
    elif [[ "$(cat /etc/issue)" == *Ubuntu* ]]; then
      distro="ubuntu"
    fi
  if [ "${distro}" == "" ]; then
    echo "Distribution NOT supported!"
    exit 1
  fi
  echo ${distro}
}

function install_cloudutils() {
  # check distro 
  distro=$(get_distro)

  which growpart >/dev/null 2>&1 
  if [ $? != 0 ]; then
    if [ ${distro} == "centos-6" ]; then
      yum install -y cloud-utils
    elif [ ${distro} == "debian" ]; then
      apt-get install -y cloud-utils
    elif [ ${distro} == "ubuntu" ]; then
      apt-get install -y cloud-utils
    fi
  if [ $? != 0 ]; then
    echo "Failed install cloud-utils."
    exit 1;
  fi
}

function install_resize_tools() {
  curl http://aos.a4c.jp/resize_tool.tar.gz -o /tmp/resize_tool.tar.gz
  if [ $? != 0 ]; then
    echo "Failed download resize_tool."
    exit 1;
  fi
  tar xzf /tmp/resize_tool.tar.gz
  cd /tmp/resize_tool
  ./install
  if [ $? != 0 ]; then
    echo "Failed install resize_tool."
    exit 1;
  fi
}

function main() {
  install_cloudutils
  install_resize_tools
  echo "Finish install."
  echo "Enjoy cloud image life."
}

main
