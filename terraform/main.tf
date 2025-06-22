terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.1.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "<Subscription-ID>" # Replace with your Azure subscription ID
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "routable_vnet" {
  name                = "routable-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "appgw_subnet" {
  name                 = "appgw-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.routable_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "workload_subnet" {
  name                 = "workload-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.routable_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_virtual_network" "internal_vnet" {
  name                = "internal-vnet"
  address_space       = ["172.16.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "app_subnet" {
  name                 = "app-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.internal_vnet.name
  address_prefixes     = ["172.16.0.0/24"]
}

resource "azurerm_public_ip" "appgw_public_ip" {
  name                = "appgw-public-ip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_application_gateway" "appgw" {
  name                = "appgw"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = azurerm_subnet.appgw_subnet.id
  }

  frontend_port {
    name = "https-port"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "appgw-fe-ip"
    public_ip_address_id = azurerm_public_ip.appgw_public_ip.id
  }

  ssl_certificate {
    name     = "appgw-ssl-cert"
    data     = filebase64("/certificate.pfx") // Replace with your certificate path
    password = "myappgwpoc"                     // Replace with your certificate password
  }

  backend_address_pool {
    name = "appgw-backend-pool"
    ip_addresses = ["172.16.0.4"]
  }

  backend_http_settings {
    name                  = "appgw-backend-http-settings"
    port                  = 3000
    protocol              = "Http"
    cookie_based_affinity = "Disabled"
    pick_host_name_from_backend_address = false
  }

  http_listener {
    name                           = "appgw-https-listener"
    frontend_ip_configuration_name = "appgw-fe-ip"
    frontend_port_name             = "https-port"
    protocol                       = "Https"
    ssl_certificate_name           = "appgw-ssl-cert"
  }

  # Add a rewrite rule set to add a custom header
  rewrite_rule_set {
    name = "ET-POC-rewrite-rules"
    rewrite_rule {
      name          = "add-certificate-sn-header-rule"
      rule_sequence = 200
        request_header_configuration {
          header_name  = "X-CLIENTCERT-SN"
          header_value = "{var_client_certificate_serial}"
        }
    }
    rewrite_rule {
      name          = "add-certificate-issuer-header-rule"
      rule_sequence = 200
        request_header_configuration {
          header_name  = "X-CLIENTCERT-ISSUER"
          header_value = "{var_client_certificate_issuer}"
        }
    }
  }
  ssl_profile {
    name                             = "appgw-ssl-profile"
    trusted_client_certificate_names  = ["trusted-root-certificate"]
    verify_client_cert_issuer_dn      = true
  }

  trusted_client_certificate {
    name = "trusted-root-certificate"
    data = filebase64("exported_certificate.cer") // Replace with your root certificate path
  }
  

  request_routing_rule {
    name                       = "https-rule"
    priority                   = 9
    rule_type                  = "Basic"
    http_listener_name         = "appgw-https-listener"
    backend_address_pool_name  = "appgw-backend-pool"
    backend_http_settings_name = "appgw-backend-http-settings"
  }
}

resource "azurerm_network_interface" "windows_web_nic" {
  name                = "windows-web-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.app_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "windows_web_server" {
  name                = "windows-web-server"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  size                = "Standard_B2ms"
  admin_username      = "azureuser"
  admin_password      = "P@ssw0rd12345!" # Change this to a secure password
  network_interface_ids = [
    azurerm_network_interface.windows_web_nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "windowswebosdisk"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  computer_name  = "winweb"
  provision_vm_agent = true

  tags = {
    environment = "dev"
  }
}

resource "azurerm_virtual_network_peering" "routable_to_internal" {
  name                      = "routable-to-internal"
  resource_group_name       = azurerm_resource_group.main.name
  virtual_network_name      = azurerm_virtual_network.routable_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.internal_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "internal_to_routable" {
  name                      = "internal-to-routable"
  resource_group_name       = azurerm_resource_group.main.name
  virtual_network_name      = azurerm_virtual_network.internal_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.routable_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
  use_remote_gateways          = false
}


resource "azurerm_public_ip" "workload_lb_public_ip" {
  name                = "workload-lb-public-ip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "workload_lb" {
  name                = "workload-lb"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "workload-lb-frontend"
    public_ip_address_id = azurerm_public_ip.workload_lb_public_ip.id
  }
}

resource "azurerm_lb_backend_address_pool" "workload_lb_backend_pool" {
  name            = "workload-lb-backend-pool"
  loadbalancer_id = azurerm_lb.workload_lb.id
}

resource "azurerm_lb_probe" "workload_lb_probe" {
  name                = "workload-lb-probe"
  loadbalancer_id     = azurerm_lb.workload_lb.id
  protocol            = "Tcp"
  port                = 80
}

resource "azurerm_network_security_group" "app_nsg" {
  name                = "workload-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowRDP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "workload_subnet_nsg_assoc" {
  subnet_id                 = azurerm_subnet.app_subnet.id
  network_security_group_id = azurerm_network_security_group.app_nsg.id
}