module "cluster" {
  source = "./modules/cluster"

  cluster_name = var.cluster_name
  k3s_version  = var.k3s_version
  http_port    = var.http_port
  https_port   = var.https_port
}
