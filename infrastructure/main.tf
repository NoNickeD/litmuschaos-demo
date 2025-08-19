resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.cluster_name}-vnet"
  address_space       = ["10.0.0.0/14"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

resource "azurerm_subnet" "aks" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.0.0/20"]
}

resource "azurerm_subnet" "pods" {
  name                 = "pods-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.1.0.0/16"]
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.cluster_name}-logs"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = var.cluster_name
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                = "system"
    vm_size             = var.vm_size
    vnet_subnet_id      = azurerm_subnet.aks.id
    pod_subnet_id       = azurerm_subnet.pods.id
    os_disk_size_gb     = 100
    os_disk_type        = "Managed"
    max_pods            = 110
    type                = "VirtualMachineScaleSets"
    enable_auto_scaling = true
    min_count           = 2
    max_count           = 5
    
    node_labels = {
      "node-type" = "system"
    }
    
    tags = var.tags
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin     = "azure"
    network_policy     = "cilium"
    network_data_plane = "cilium"
    dns_service_ip     = "10.10.0.10"
    service_cidr       = "10.10.0.0/16"
    load_balancer_sku  = "standard"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  }

  azure_policy_enabled             = true
  http_application_routing_enabled = false
  
  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  workload_identity_enabled = true
  oidc_issuer_enabled       = true

  tags = var.tags
  
  lifecycle {
    ignore_changes = [default_node_pool[0].node_count]
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "workload" {
  name                  = "workload"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = "Standard_D4s_v5"
  vnet_subnet_id        = azurerm_subnet.aks.id
  pod_subnet_id         = azurerm_subnet.pods.id
  max_pods              = 110
  os_disk_size_gb       = 100
  os_disk_type          = "Managed"
  enable_auto_scaling   = true
  min_count             = 3
  max_count             = 6

  node_labels = {
    "node-type" = "workload"
    "workload"  = "demo"
  }

  node_taints = [
    "workload=demo:NoSchedule"
  ]

  tags = var.tags
  
  lifecycle {
    ignore_changes = [node_count]
  }
}

resource "azurerm_container_registry" "main" {
  name                = "${replace(var.cluster_name, "-", "")}acr"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  admin_enabled       = false
  tags                = var.tags
}

resource "azurerm_role_assignment" "aks_acr" {
  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.main.id
  skip_service_principal_aad_check = true
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "8.3.0"
  namespace  = "argocd"
  create_namespace = true

  values = [
    yamlencode({
      server = {
        service = {
          type = "ClusterIP"
        }
        extraArgs = ["--insecure"]
      }
      configs = {
        params = {
          "server.insecure" = true
        }
      }
    })
  ]

  depends_on = [azurerm_kubernetes_cluster.main]
}