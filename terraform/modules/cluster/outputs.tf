output "cluster_name" {
  description = "The k3d cluster name."
  value       = null_resource.k3d_cluster.triggers.cluster_name
}

output "kubeconfig_context" {
  description = "The kubectl context name that reaches this cluster (k3d prefixes with k3d-)."
  value       = "k3d-${var.cluster_name}"
}
