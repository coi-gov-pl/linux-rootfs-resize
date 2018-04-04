require 'spec_helper'

describe 'On Debian 8 - jessie' do

  it_behaves_like 'fully working linux-rootfs-resize script',
    box: 'bento/debian-8'
end
