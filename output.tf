output "private_key" {
  value = module.key.private_key
}

output "linux_hosts" {
  value = { for ngn, v in local.nodegroups_linux : ngn => module.linux_vmms[ngn].linux_hosts }
}

output "windows_hosts" {
  value = { for ngn, v in local.nodegroups_windows : ngn => module.windows_vmms[ngn].windows_hosts }
}
