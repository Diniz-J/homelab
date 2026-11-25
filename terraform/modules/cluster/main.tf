resource "null_resource" "k3d_cluster" {
  triggers = {
    cluster_name = var.cluster_name
    k3s_version  = var.k3s_version
    http_port    = var.http_port
    https_port   = var.https_port
    network      = var.network
    registry     = var.registry
  }

  provisioner "local-exec" {
    command = join(" ", concat([
      "k3d cluster create ${var.cluster_name}",
      "--image rancher/k3s:${var.k3s_version}",
      "--port ${var.http_port}:80@loadbalancer",
      "--port ${var.https_port}:443@loadbalancer",
      "--k3s-arg '--disable=traefik@server:0'",
      "--wait",
      ],
      var.network != "" ? ["--network ${var.network}"] : [],
      var.registry != "" ? ["--registry-use ${var.registry}"] : [],
    ))
  }

  provisioner "local-exec" {
    when    = destroy
    command = "k3d cluster delete ${self.triggers.cluster_name}"
  }
}
