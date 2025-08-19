variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "litmuschaos-demo-rg"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "westeurope"
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "litmuschaos-demo-aks"
}

variable "kubernetes_version" {
  description = "Kubernetes version for AKS"
  type        = string
  default     = "1.33"
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 3
}

variable "vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_D4s_v5"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "demo"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "demo"
    Project     = "litmuschaos"
    ManagedBy   = "opentofu"
    CNCF        = "true"
  }
}
