############################################################################
# Allocates a developer VM in Azure
############################################################################

// -------------------------------------------------------------------------
// Configurations
// -------------------------------------------------------------------------
variable "subsId" {
    default = ""
}

variable "clientId" {
    default = ""
}

variable "secret" {
    default = ""
}

variable "tenantId" {
    default = ""
}

variable "region" {
    default = "westus2"
}

// TODO: This will be larger, try F8s OR F16s
variable vm_size {
    default = "Standard_F2s"
}

variable "userName" {
    description = "E.g. your name abhinaba, for second machine use say abhinaba2"
}

// TODO: accept ssh keys
variable "password" {
    description = "Password for user"
}

// -------------------------------------------------------------------------
// Azure setup
// -------------------------------------------------------------------------
provider "azurerm" { 
    subscription_id = "${var.subsId}"
    client_id       = "${var.clientId}"
    client_secret   = "${var.secret}"
    tenant_id       = "${var.tenantId}"
}

resource "azurerm_resource_group" "rg" {
    name = "cloudDevBoxVMResourceGroup"
    location = "${var.region}"
    tags {
        environment = "Developer boxes"
    }
}

// -------------------------------------------------------------------------
// Networking
// -------------------------------------------------------------------------
resource "azurerm_virtual_network" "devVNet" {
    name                = "${var.userName}cloudDevBoxVmVnet"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    location            = "${var.region}"
    address_space       = ["10.0.0.0/16"]
    
}

resource "azurerm_subnet" "devSubnet" {
    name                    = "${var.userName}cloudDevBoxVmSubnet"
    resource_group_name     = "${azurerm_resource_group.rg.name}"
    virtual_network_name    = "${azurerm_virtual_network.devVNet.name}"
    address_prefix          = "10.0.2.0/24"
}

resource "azurerm_public_ip" "devPublicIp" {
    name                            = "${var.userName}CloudDevBoxPublicIp"
    resource_group_name             = "${azurerm_resource_group.rg.name}"
    location                        = "${var.region}"
    public_ip_address_allocation    = "dynamic"
    idle_timeout_in_minutes         = 30
    domain_name_label               = "${var.userName}-clouddevbox"
}

locals {
    vmFqdn = "${azurerm_public_ip.devPublicIp.fqdn}"
}

// Todo add rule for rdp/ssh from home ip address 102 103
variable "network_rules" {
    default = {
        "0" = "131.107.0.0/16,22,TCP"
        "1" = "131.107.0.0/16,3389,TCP"
        "2" = "207.68.190.32/27,22,TCP"
        "3" = "207.68.190.32/27,3389,TCP"
        "4" = "52.250.118.235,22,TCP"
        "5" = "52.250.118.235,3389,TCP"
    }
}

resource "azurerm_network_security_group" "devNsg" {
    name = "${var.userName}CloudDevBoxNsg"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    location            = "${var.region}"

    security_rule {
        direction                   = "Inbound"
        priority                    = 200
        name                        = "AllowVnetInBound"
        destination_port_range      = "*"
        protocol                    = "*"
        source_address_prefix       = "VirtualNetwork"
        source_port_range           = "*"
        destination_address_prefix  = "VirtualNetwork"
        access                      = "Allow"
    }

    security_rule {
        direction                   = "Inbound"
        priority                    = 201
        name                        = "AllowAzLoadBalancer"
        destination_port_range      = "*"
        protocol                    = "*"
        source_address_prefix       = "AzureLoadBalancer"
        source_port_range           = "*"
        destination_address_prefix  = "*"
        access                      = "Allow"
    }

    security_rule {
        direction                   = "Inbound"
        priority                    = 4096
        name                        = "DenyAllInBound"
        destination_port_range      = "*"
        protocol                    = "*"
        source_address_prefix       = "*"
        source_port_range           = "*"
        destination_address_prefix  = "*"
        access                      = "Deny"
    }

    security_rule {
        direction                   = "Outbound"
        priority                    = 300
        name                        = "AllowVnetOutBound"
        destination_port_range      = "*"
        protocol                    = "*"
        source_address_prefix       = "VirtualNetwork"
        source_port_range           = "*"
        destination_address_prefix  = "VirtualNetwork"
        access                      = "Allow"
    }
    
    security_rule {
        direction                   = "Outbound"
        priority                    = 301
        name                        = "AllowInternetOutBound"
        destination_port_range      = "*"
        protocol                    = "*"
        source_address_prefix       = "*"
        source_port_range           = "*"
        destination_address_prefix  = "Internet"
        access                      = "Allow"
    }
    
    security_rule {
        direction                   = "Outbound"
        priority                    = 4096
        name                        = "DenyAllOutBound"
        destination_port_range      = "*"
        protocol                    = "*"
        source_address_prefix       = "*"
        source_port_range           = "*"
        destination_address_prefix  = "*"
        access                      = "Deny"
    }
}

resource "azurerm_network_security_rule" "allowrules" {
    name                        = "${var.userName}rules"
    resource_group_name         = "${azurerm_resource_group.rg.name}"
    network_security_group_name = "${azurerm_network_security_group.devNsg.name}"

    direction                   = "Inbound"
    priority                    = "${count.index + 100}"
    name                        = "Rule${count.index}"
    source_address_prefix       = "${element(split(",", var.network_rules[count.index]), 0)}"
    destination_port_range      = "${element(split(",", var.network_rules[count.index]), 1)}"
    protocol                    = "${element(split(",", var.network_rules[count.index]), 2)}"
    source_port_range           = "*"
    destination_address_prefix  = "*"
    access                      = "Allow"

    count = "${length(var.network_rules)}"
}

resource "azurerm_network_interface" "devNic" {
    name                      = "${var.userName}CloudDevBoxNetworkInterface"
    resource_group_name       = "${azurerm_resource_group.rg.name}"
    location                  = "${var.region}"
    network_security_group_id = "${azurerm_network_security_group.devNsg.id}"

    ip_configuration {
        name                            = "${var.userName}CloudDevBoxNicConfig"
        subnet_id                       = "${azurerm_subnet.devSubnet.id}"
        private_ip_address_allocation   = "dynamic"
        public_ip_address_id            = "${azurerm_public_ip.devPublicIp.id}"
    }
}

// -------------------------------------------------------------------------
// Storage
// -------------------------------------------------------------------------
resource "random_id" "randomId" {
    keepers = {
        resource_group  = "${azurerm_resource_group.rg.name}"
    }

    byte_length         = 8
}

// Storage account for diagnostics
resource "azurerm_storage_account" "diagStorage" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = "${azurerm_resource_group.rg.name}"
    location                    = "${var.region}"
    account_replication_type    = "LRS"
    account_tier                = "Standard"
}

// -------------------------------------------------------------------------
// Finally the VM
// -------------------------------------------------------------------------
resource "azurerm_virtual_machine" "devVirtualMachine" {
    name = "${var.userName}CloudDevBox"
    resource_group_name         = "${azurerm_resource_group.rg.name}"
    location                    = "${var.region}"
    network_interface_ids       = ["${azurerm_network_interface.devNic.id}"]
    vm_size                     = "${var.vm_size}"

    storage_os_disk {
        name = "osDisk${var.userName}"
        caching = "ReadWrite"
        create_option = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    delete_os_disk_on_termination = true

    storage_image_reference {
        publisher   = "Canonical"
        offer       = "UbuntuServer"
        sku         = "16.04.0-LTS"
        version     = "latest"
    }

    os_profile {
        computer_name  = "${var.userName}CloudDevBox"
        admin_username = "${var.userName}"
        admin_password = "${var.password}"
    }

    os_profile_linux_config {
        disable_password_authentication = false
    }

    boot_diagnostics {
        enabled     = "true"
        storage_uri = "${azurerm_storage_account.diagStorage.primary_blob_endpoint}"
    }
    
    tags {
        generatedby = "terraform"
        author      = "abhinab@microsoft.com"
    }
    
    provisioner "file" {
        source = "cloudVMsetup.sh"
        destination = "/tmp/cloudVMsetup.sh"

        connection {
            type     = "ssh"
            user     = "${var.userName}"
            password = "${var.password}"
            timeout  = "20m"
            host     = "${local.vmFqdn}"
        }
    }

    provisioner "remote-exec" {
        inline = [
            "whoami > /tmp/started",
            "chmod +x /tmp/cloudVMsetup.sh",
            "/tmp/cloudVMsetup.sh",
            "whoami > /tmp/end",
        ]

        connection {
            type     = "ssh"
            user     = "${var.userName}"
            password = "${var.password}"
            timeout  = "20m"
            host     = "${local.vmFqdn}"
        }
    }
}

// -------------------------------------------------------------------------
// Print out login information
// -------------------------------------------------------------------------
output "ip" {
  value = "Created vm ${azurerm_virtual_machine.devVirtualMachine.id}"
  value = "Connect using ${var.userName}@${local.vmFqdn}"
}
