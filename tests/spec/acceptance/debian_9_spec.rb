require 'spec_helper'

describe 'On Debian 9 - stretch' do

  it_behaves_like 'fully working linux-rootfs-resize script',
    box: 'bento/debian-9'
end
