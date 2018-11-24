# --------------------------------
# NON-DEFAULTS
# --------------------------------
# passed from the calling module

variable "vm_name" {
    description = "VM name"
}

variable "vm_ip" {
    description = "VM IP address"
}

variable "vm_template" {
    description = "VM Template to clone from"
}

# --------------------------------
# DEFAULTS
# --------------------------------
# REQUIRED TO SPECIFY HERE, OR PASS FROM CALLING MODULE
# Here, specify as: default = "<VALUE>"

variable "vm_folder" {
    description = "VM folder location"
    default = ""  # root folder
}

variable "vm_datacenter" {
    description = "VM data center"    
}

variable "vm_vcpu_number" {
    description = "vCPU for the VM"
}

variable "vm_memory_size" {
    description = "RAM for the VM"
}

variable "vm_datastore" {
    description = "VM datastore"
}

variable "vm_domain" {
    description = "VM domain"
}

variable "vm_time_zone" {
    description = "VM timezone"
}

variable "vm_network" {
    description = "VM network"
}

variable "vm_resource_pool" {
    description = "VM resource pool"
}

variable "vm_scsi_type" {
    description = "SCSI type"
}

variable "vm_dns_servers" {
    description = "VM DNS server list, separated by commas"
}
