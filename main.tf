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