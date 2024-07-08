name = "mirantis"

location = "East US"

subnets = {
  "AMain" = {
    cidr       = "172.31.0.0/17"
    nodegroups = ["AMngr", "AWrkr"]
    private    = false
  }
  "APriv" = {
    cidr       = "172.31.128.0/17"
    nodegroups = ["AWrkPriv"]
    private    = true
  }
}

// configure the network stack
network = {
  enable_vpn_gateway = false
  enable_nat_gateway = false
  cidr               = "172.31.0.0/16"
}

nodegroups = {
  "AMngr" = {
    platform    = "ubuntu_22.04"
    count       = 1
    type        = "Standard_DS2_v2"
    role        = "manager"
    public      = true
    volume_size = 100
  },
  "AWrkPriv" = {
    platform    = "ubuntu_22.04"
    count       = 1
    type        = "Standard_DS2_v2"
    role        = "manager"
    public      = true
    volume_size = 100
  },
}

common_tags = {
  environment = "dev"
  project     = "mirantis"
  owner       = "mirantis"
}

// set a windows password, if you have windows nodes
# windows_password = ""
