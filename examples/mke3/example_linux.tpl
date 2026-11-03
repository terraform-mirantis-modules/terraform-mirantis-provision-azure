#cloud-config
# Minimal cloud-init for the linux nodegroups. A linux nodegroup cannot be
# provisioned without one: modules/nodegroup_linux sets
# custom_data = base64encode(var.user_data) unconditionally, and the provider
# rejects both null ("argument must not be null") and "" ("expected
# custom_data to not be an empty string").
write_files:
  - path: /var/log/startup_log.txt
    permissions: "0644"
    content: |
      provisioned for ${user}
