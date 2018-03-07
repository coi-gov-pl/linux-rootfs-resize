require 'spec_helper'

describe 'On OracleLinux 7' do

  it_behaves_like 'fully working linux-rootfs-resize script',
    box: 'bento/oracle-7.4'
end
