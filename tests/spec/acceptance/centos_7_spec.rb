require 'spec_helper'

describe 'On CentOS 7' do

  it_behaves_like 'fully working linux-rootfs-resize script',
    box: 'bento/centos-7.4'
end
