# linux-rootfs-resize

Supported Linux distributions (tested):

* CentOS 6,
* CentOS 7,
* OracleLinux 6,
* OracleLinux 7,
* Debian 7,
* Debian 8,
* Debian 9,
* Ubuntu 14.04,
* Ubuntu 16.04,
* Ubuntu 18.04


This tool creates new initrd (initramfs) image with ability to resize root filesystem over available space. Tipically you need this when you provision your virtual machine on OpenStack cloud for the first time (your image becomes flavor aware).

Resize for LVM and native partitions and for EXT and XFS filesystems.

This code should support any RHEL 6 and 7 system as well as varaity of Debian like systems.

Dependencies (are installed if needed):

 * bash
 * cloud-utils (https://launchpad.net/cloud-utils)
 * parted


## Automatic web install script

If you like there a auto install script suitable for automatic installation. Script fetches last release and executes it.

With CURL:

```bash
curl -L https://raw.githubusercontent.com/coi-gov-pl/linux-rootfs-resize/v2.0.0/auto-install | bash
```

## Automatic installation

You can also fetch this tool for your self using GIT and execute it:

```bash
git clone https://github.com/coi-gov-pl/linux-rootfs-resize.git \
  -o ~/opt/linux-rootfs-resize
~/opt/linux-rootfs-resize/install
```

## Development & Testing

Tool has been redesigned in modular, application like fashion, so support for other distributions can be added without much work.

Tests requires:

 * Vagrant
 * VirtualBox
 * Ruby >= 2.4

### Automated tests

There are automatic tests located in `tests` directory. To invoke them you need to have Ruby >= 2.4 - easiest to do with RVM:

```bash
cd tests
rvm use 2.4
bundle
bundle exec rake spec
```

### Development testing

To develop some changes you can utilize Vagrant environments (located in `tests` directory), so you can run the same test as in automatic tests, but with step by step manner. In that way you can instect the outcome:

```bash
cd tests
rvm use 2.4
bundle
vagrant up centos7 # Spin up VM and perform script
vagrant halt centos7 # Halts machine to be able to resize HDD
bundle exec rake centrifuge:resize[centos7] # Resize HDD of VM to 120G by default
vagrant up centos7 # Spins up VM again (Initramfs should kicks in)
vagrant ssh centos7 -c 'df -h' # Confirm the root partition has resized
```
## Contributing

1. Fork it ( https://github.com/coi-gov-pl/linux-rootfs-resize/fork )
2. Create your feature branch (`git checkout -b feature/my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin feature/my-new-feature`)
5. Create a new Pull Request
