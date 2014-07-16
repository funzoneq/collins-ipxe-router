collins-ipxe-router
===================

A simple iPXE router based on collins data

# Example dhcpd.conf

```
subnet 192.168.1.0 netmask 255.255.255.0 {
  option domain-name        "example.com";
  option routers            192.168.1.1;
  default-lease-time        21600;
  max-lease-time            43200;
  range                     192.168.1.21 192.168.1.254;

  # If a pxe request comes in from ipxe send the config url
  if exists user-class and option user-class = "iPXE" {
    filename "http://192.168.1.5:4567/pxe/${net0/mac}"; # http://foo.example.com/ipxe/${net0/mac}
  # For all other pxe requests send ipxe
  } else {
    next-server 192.168.1.5;    # tftp server
    filename "/pxelinux.0";     # path to ipxe binary on tftp server
  }
}
```
