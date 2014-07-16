collins-ipxe-router
===================

A simple iPXE router based on collins data


## Setup TFTP

```
sudo yum -y install dhcp tftp-server
sudo sed -i 's/disable\s*=\s*yes/disable = no/' /etc/xinetd.d/tftp
cd /var/lib/tftpboot/
sudo wget http://boot.ipxe.org/undionly.kpxe
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

  # If a pxe request comes in from ipxe send the config url
  if exists user-class and option user-class = "iPXE" {
    filename "http://192.168.1.5:4567/pxe/${net0/mac}";
  # For all other pxe requests send ipxe
  } else {
    next-server 192.168.1.5;    # tftp server
    filename "/undionly.kpxe";     # path to ipxe binary on tftp server
  }
}
```
