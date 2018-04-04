require 'spec_helper'

describe 'On Ubuntu 14.04' do

  it_behaves_like 'fully working linux-rootfs-resize script',
    box: 'bento/ubuntu-14.04'
end
