# Terraform vShpere

This project repository provides modules which you can use to deploy virtual machine resources in your vCenter and customize them. There are modules for windows/linux machines with static and dynamic IP custom configurations. 

This repo also serves as example code for the Post <>.

There is also an example main.tf file which you can use as reference. Please look out for the comment 'REQUIRED'. The variables marked with that comment are required to be specified. 

## modules/windows_static
Module to deploy a windows VM with static IP. You need to configure a network interface, specify IP address, default gateway, and DNS servers.

## modules/windows_dhcp
Module to deploy a windows VM with DHCP. You only need to specify an empty network interface.

## modules/linux_static
Module to deploy a linux VM with static IP. You need to configure a network interface, specify IP address, and DNS servers.

## modules/linux_dhcp
Module to deploy a linux VM with DHCP. You only need to specify an empty network interface.

## Limitations:
* Unable to pass JSON/map variables to modules. Can only pass string variables.
* Cannot interpolate variables i.e. cannot construct variables from other variables.
* There is no way to decode JSON string. 
* No concept of global variables. Cannot specify a variable in root module and resuse in the child module.
* Cannot pass a .tfvars file as input parameter when calling the child module. 
* Cannot have a terraform.tfvars file for child module. Hence, the only way to override default variable values is by specifying them as parameters when calling the module. 
