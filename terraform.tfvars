name = "dddt"

nodegroups = {
  "AMngr" = {
    platform    = "ubuntu_22.04"
    count       = 2
    type        = "Standard_DS2_v2"
    role        = "manager"
    public      = true
    volume_size = 100
  },
  "AWrkr" = {
    platform    = "windows_2022"
    count       = 1
    type        = "Standard_DS2_v2"
    role        = "worker"
    public      = true
    volume_size = 200
  },
}

common_tags = {
  environment = "dev"
  project     = "dddt"
  owner       = "dimitar"
}
