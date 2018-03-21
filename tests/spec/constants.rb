module Constants
  MEGABYTES = 1024 * 1024
  module Commands
    GET_ROOT_PARTITION_SIZE = <<~eos
    export LANG=C
    disk=$(mount | grep ' on / ' | awk '{print $1}')
    bytes=$(fdisk -l $disk | grep 'Disk /' | awk '{print $5}')
    awk -vbytes=$bytes "BEGIN {print bytes/(1024*1024)}"
    eos
  end
end
