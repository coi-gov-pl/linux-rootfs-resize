require 'spec_helper'

describe 'On OracleLinux 6' do

  it_behaves_like 'fully working linux-rootfs-resize script',
    box: 'bento/oracle-6'
end
