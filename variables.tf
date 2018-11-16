# -------------------------------------------------------
# PROVIDER CONFIGURATION VARIABLES
# -------------------------------------------------------

variable "vsphere_user" {
    description = "vSphere user name"
}

variable "vsphere_password" {
    description = "vSphere password"
}

variable "vsphere_vcenter" {
    description = "vCenter server FQDN or IP"
}

variable "vsphere_unverified_ssl" {
    description = "Is the vCenter using a self signed certificate (true/false)"
}

# -------------------------------------------------------
# RESOURCE CONFIGURATION VARIABLES
# -------------------------------------------------------

variable "vm_datacenter" {
    description = "vSphere data center"
}

variable "vm_win_template" {
    description = "VM template for Windows"
}

variable "vm_linux_template" {
    description = "VM template for Linux"
}

