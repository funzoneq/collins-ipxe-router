collins-ipxe-router
===================

A simple iPXE router based on collins data


## Setup TFTP

```
sudo yum -y install dhcp tftp-server nginx
sudo sed -i 's/disable\s*=\s*yes/disable = no/' /etc/xinetd.d/tftp
cd /var/lib/tftpboot/
sudo wget http://boot.ipxe.org/undionly.kpxe
sudo mkdir -p /usr/share/nginx/html/mirror/
sudo mkdir -p /usr/share/nginx/html/mirror/{omw,omw_test,centos,ubuntu}
sudo vi /etc/dhcp/dhcpd.conf
```

## Example dhcpd.conf

```
allow booting;
allow bootp;
option option-128 code 128 = string;
option option-129 code 129 = text;

subnet 192.168.1.0 netmask 255.255.255.0 {
  option domain-name          "example.com";
  option routers              192.168.1.1;
  option domain-name-servers  8.8.8.8, 4.2.2.2;
  default-lease-time          21600;
  max-lease-time              43200;
  range                       192.168.1.21 192.168.1.254;
  next-server                 192.168.1.5;    # tftp server

  # If a pxe request comes in from ipxe send the config url
  if exists user-class and option user-class = "iPXE" {
    filename "http://192.168.1.5:4567/pxe/${net0/mac}";
  # For all other pxe requests send ipxe
  } else {
    filename "/undionly.kpxe";     # path to ipxe binary on tftp server
  }
}
```

## Example Ubuntu amd64 kickstart

```
cd /usr/share/nginx/html/mirror/ubuntu/
wget http://archive.ubuntu.com/ubuntu/dists/trusty-updates/main/installer-amd64/current/images/netboot/ubuntu-installer/amd64/initrd.gz
wget http://archive.ubuntu.com/ubuntu/dists/trusty-updates/main/installer-amd64/current/images/netboot/ubuntu-installer/amd64/linux
```

## Example CentOS x86_64 kickstart

```
cd /usr/share/nginx/html/mirror/centos/
wget http://mirror.centos.org/centos/7/os/x86_64/images/pxeboot/initrd.img
wget http://mirror.centos.org/centos/7/os/x86_64/images/pxeboot/vmlinuz
```

## Example OnMyWay x86_64 setup

```
cd /usr/share/nginx/html/mirror/omw/
wget http://vps.us.freshway.biz/OnMyWay/LATEST -O omw.iso
```
