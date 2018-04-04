require 'spec_helper'

describe 'On Ubuntu 16.04' do

  it_behaves_like 'fully working linux-rootfs-resize script',
    box: 'bento/ubuntu-16.04'
end
