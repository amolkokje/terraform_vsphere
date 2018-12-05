# -------------------------------------------------------
# FOLDER RESOURCES
# -------------------------------------------------------

data "vsphere_datacenter" "dc" {
    name = "${var.vm_datacenter}"
}

resource "vsphere_folder" "test_folder" {
    path          = "test_folder"
    type          = "vm"
    datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

# -------------------------------------------------------
# VIRTUAL MACHINE RESOURCES
# -------------------------------------------------------

# Terraform Customization will work if installed all dependencies, only on the supported OS list
# Dependencies: https://kb.vmware.com/s/article/2075048
# Supported OS list: https://partnerweb.vmware.com/programs/guestOS/guest-os-customization-matrix.pdf

module "win-dhcp" {
    source      = "modules/windows_dhcp/"
    vm_name     = "test-win-dhcp"
    vm_folder   = "${vsphere_folder.test_folder.path}"
    vm_template = "${var.vm_win_template}"
}

module "win-static" {
    source      = "modules/windows_static/"
    vm_name     = "test-win-static"
    vm_folder   = "${vsphere_folder.test_folder.path}"
    vm_template = "${var.vm_win_template}"
    vm_ip       = ""  # REQUIRED
}

module "linux-dhcp" {
    source      = "modules/linux_dhcp/"
    vm_name     = "test-linux-dhcp"
    vm_folder   = "${vsphere_folder.test_folder.path}"
    vm_template = "${var.vm_linux_template}"
}

module "linux-static" {
    source      = "modules/linux_static/"
    vm_name     = "test-linux-static"
    vm_folder   = "${vsphere_folder.test_folder.path}"
    vm_template = "${var.vm_linux_template}"
    vm_ip       = ""  # REQUIRED
}

# Example of using a Customization script, if your VM does not have all the dependencies, or is not supported. 

module "linux-dhcp-script" {
    source      = "modules/linux_dhcp_script/"
    vm_name     = "test-linux-dhcp-script"
    vm_folder   = "${vsphere_folder.test_folder.path}"
    vm_template = "${var.vm_linux_template}"
}

module "linux-static-script" {
    source      = "modules/linux_static_script/"
    vm_name     = "test-linux-static-script"
    vm_folder   = "${vsphere_folder.test_folder.path}"
    vm_template = "${var.vm_linux_template}"
    vm_ip       = ""  # REQUIRED
}



