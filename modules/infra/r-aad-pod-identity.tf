data "azurerm_resource_group" "aks_nodes_rg" {
  name = var.aks_resource_group_name
}

resource "kubernetes_namespace" "add_pod_identity" {
  metadata {
    name = var.aadpodidentity_namespace
    labels = {
      deployed-by = "Terraform"
    }
  }
}

resource "helm_release" "aad_pod_identity" {
  name       = "aad-pod-identity"
  repository = "https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts"
  chart      = "aad-pod-identity"
  version    = var.aadpodidentity_chart_version
  namespace  = kubernetes_namespace.add_pod_identity.metadata.0.name

  dynamic "set" {
    for_each = local.aadpodidentity_values
    iterator = setting
    content {
      name  = setting.key
      value = setting.value
    }
  }
}

resource "azurerm_user_assigned_identity" "aad_pod_identity" {
  location            = var.location
  name                = "aad-pod-identity"
  resource_group_name = var.aks_resource_group_name
}
resource "azurerm_role_assignment" "aad_pod_identity_msi" {
  scope                = data.azurerm_resource_group.aks_nodes_rg.id
  principal_id         = azurerm_user_assigned_identity.aad_pod_identity.principal_id
  role_definition_name = "Managed Identity Operator"
}

