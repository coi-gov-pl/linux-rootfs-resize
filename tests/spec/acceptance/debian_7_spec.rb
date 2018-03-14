require 'spec_helper'

describe 'On Debian 7 - wheezy' do

  it_behaves_like 'fully working linux-rootfs-resize script',
    box: 'bento/debian-7'
end
