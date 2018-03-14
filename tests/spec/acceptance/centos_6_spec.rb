require 'spec_helper'

describe 'On CentOS 6' do

  it_behaves_like 'fully working linux-rootfs-resize script',
    box: 'bento/centos-6'
end
