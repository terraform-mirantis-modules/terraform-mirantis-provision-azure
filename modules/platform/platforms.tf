
locals {
  // this is the idea of @jcarrol who put this into a lib map. Here we steal his idea
  lib_platform_definitions = {
    // URNs verified 2026-10-24 via `az vm image show` in westeurope: the
    // previous Canonical offer "ubuntu" does not resolve.
    "ubuntu_20.04" : {
      "sku" : "20_04-lts-gen2",
      "publisher" : "Canonical",
      "offer" : "0001-com-ubuntu-server-focal",
      "version" : "latest",
      "plan" : false,
      "interface" : "eth0"
      "connection" : "ssh",
      "ssh_user" : "ubuntu",
      "ssh_port" : 22,
      "type" : "linux"
    },
    "ubuntu_22.04" : {
      "sku" : "22_04-lts-gen2",
      "publisher" : "Canonical",
      "offer" : "0001-com-ubuntu-server-jammy",
      "version" : "latest",
      "plan" : false,
      "interface" : "eth0"
      "connection" : "ssh",
      "ssh_user" : "ubuntu",
      "ssh_port" : 22,
      "type" : "linux"
    },
    "ubuntu_24.04" : {
      "sku" : "server",
      "publisher" : "Canonical",
      "offer" : "ubuntu-24_04-lts",
      "version" : "latest",
      "plan" : false,
      "interface" : "eth0"
      "connection" : "ssh",
      "ssh_user" : "ubuntu",
      "ssh_port" : 22,
      "type" : "linux"
    },
    "centos_8_2" : {
      "sku" : "8_2-gen2",
      "publisher" : "OpenLogic",
      "offer" : "CentOS",
      "version" : "latest",
      "interface" : "eth0"
      "connection" : "ssh",
      "ssh_user" : "ubuntu",
      "ssh_port" : 22,
      "type" : "linux"
    },
    // resf Rocky images carry a marketplace purchase plan; the plan flag makes
    // the nodegroup modules emit the plan block (terms must be accepted once
    // per subscription: az vm image terms accept --urn resf:rockylinux-x86_64:<sku>:latest)
    "rocky_8" : {
      "sku" : "8-base",
      "publisher" : "resf",
      "offer" : "rockylinux-x86_64",
      "version" : "latest",
      "plan" : true,
      "interface" : "eth0"
      "connection" : "ssh",
      "ssh_user" : "rocky",
      "ssh_port" : 22,
      "type" : "linux"
    },
    "rocky_9" : {
      "sku" : "9-base",
      "publisher" : "resf",
      "offer" : "rockylinux-x86_64",
      "version" : "latest",
      "plan" : true,
      "interface" : "eth0"
      "connection" : "ssh",
      "ssh_user" : "rocky",
      "ssh_port" : 22,
      "type" : "linux"
    },
    "rhel_8" : {
      "sku" : "8-lvm-gen2",
      "publisher" : "RedHat",
      "offer" : "RHEL",
      "version" : "latest",
      "interface" : "eth0"
      "connection" : "ssh",
      "ssh_user" : "rhel",
      "ssh_port" : 22,
      "type" : "linux"
    },
    "rhel_8.10" : {
      "sku" : "810-gen2",
      "publisher" : "RedHat",
      "offer" : "RHEL",
      "version" : "latest",
      "interface" : "eth0"
      "connection" : "ssh",
      "ssh_user" : "rhel",
      "ssh_port" : 22,
      "type" : "linux"
    },
    "rhel_9.0" : {
      "sku" : "90-gen2",
      "publisher" : "RedHat",
      "offer" : "RHEL",
      "version" : "latest",
      "interface" : "eth0"
      "connection" : "ssh",
      "ssh_user" : "rhel",
      "ssh_port" : 22,
      "type" : "linux"
    },
    "rhel_9.5" : {
      "sku" : "95_gen2",
      "publisher" : "RedHat",
      "offer" : "RHEL",
      "version" : "latest",
      "interface" : "eth0"
      "connection" : "ssh",
      "ssh_user" : "rhel",
      "ssh_port" : 22,
      "type" : "linux"
    },
    "sles_12_sp4" : {
      "sku" : "gen2",
      "publisher" : "SUSE",
      "offer" : "12-sp4-gen2",
      "version" : "latest",
      "interface" : "eth0"
      "connection" : "ssh",
      "ssh_user" : "sles",
      "ssh_port" : 22,
      "type" : "linux"
    },
    "sles_15_sp5" : {
      "sku" : "gen2",
      "publisher" : "SUSE",
      "offer" : "sles-15-sp5",
      "version" : "latest",
      "interface" : "eth0"
      "connection" : "ssh",
      "ssh_user" : "sles",
      "ssh_port" : 22,
      "type" : "linux"
    },
    "windows_2019" : {
      "sku" : "2019-datacenter-gensecond",
      "publisher" : "MicrosoftWindowsServer",
      "offer" : "WindowsServer",
      "version" : "latest",
      "interface" : "Ethernet 3"
      "connection" : "winrm",
      "winrm_user" : "miradmin",
      "winrm_useHTTPS" : true,
      "winrm_insecure" : true,
      "type" : "windows"
    },
    "windows_2022" : {
      "sku" : "2022-datacenter-g2",
      "publisher" : "MicrosoftWindowsServer",
      "offer" : "WindowsServer",
      "version" : "latest",
      "interface" : "Ethernet 3"
      "connection" : "winrm",
      "winrm_user" : "miradmin",
      "winrm_useHTTPS" : true,
      "winrm_insecure" : true,
      "type" : "windows"
    }
  }
}
