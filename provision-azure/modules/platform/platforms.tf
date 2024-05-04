
locals {
  // this is the idea of @jcarrol who put this into a lib map. Here we steal his idea
  lib_platform_definitions = {
    "ubuntu_22.04" : {
      "sku" : "22_04-lts-gen2",
      "publisher" : "Canonical",
      "offer" : "0001-com-ubuntu-server-jammy",
      "version" : "latest",
      "interface" : "eth0"
      "connection" : "ssh",
      "ssh_user" : "ubuntu",
      "ssh_port" : 22,
      "type" : "linux"
    },
    "windows_2022" : {
      "sku" : "2022-datacenter-g2",
      "publisher" : "MicrosoftWindowsServer",
      "offer" : "WindowsServer",
      "version" : "latest",
      "interface" : "Ethernet 3"
      "connection" : "winrm",
      "winrm_user" : "Administrator",
      "winrm_useHTTPS" : true,
      "winrm_insecure" : true,
      "type" : "windows"
    },
  }
}
