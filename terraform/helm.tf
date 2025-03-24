provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.chat_app_eks.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.chat_app_eks.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.chat_app_eks.name]
      command     = "aws"
    }
  }
}
provider "kubernetes" {
  host                   = aws_eks_cluster.chat_app_eks.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.chat_app_eks.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.chat_app_eks.name]
    command     = "aws"
  }
}
resource "kubernetes_service_account" "aws_load_balancer_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.aws_load_balancer_controller.arn
    }
  }
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  
  set {
    name  = "clusterName"
    value = aws_eks_cluster.chat_app_eks.name
  }
  
  set {
    name  = "serviceAccount.create"
    value = "false"
  }
  
  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.aws_load_balancer_controller.metadata[0].name
  }
  
  depends_on = [
    aws_eks_cluster.chat_app_eks,
    aws_eks_node_group.chat_app_node_group,
    kubernetes_service_account.aws_load_balancer_controller
  ]
}