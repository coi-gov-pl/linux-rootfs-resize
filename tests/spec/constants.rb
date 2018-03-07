module Constants
  MEGABYTES = 1024 * 1024
  module Commands
    GET_ROOT_PARTITION_SIZE = <<~eos
    LANG=C df -B#{MEGABYTES} | grep -E '/$' | awk '{print $2}'
    eos
  end
end
