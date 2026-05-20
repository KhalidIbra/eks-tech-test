output "cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "cluster_ca_certificate" {
  value = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_name" {
  value = aws_eks_cluster.main.name
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.eks.arn
}

output "node_security_group_id" {
  value = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "aws_load_balancer_controller_role_arn" {
  value = aws_iam_role.aws_load_balancer_controller.arn
}

output "repository_url" {
  value = module.ecr.repository_url
}

output "aws_load_balancer_controller_role_arn" {
  value = module.eks.aws_load_balancer_controller_role_arn
}

output "db_credentials_secret_name" {
  value = module.rds.db_credentials_secret_name
}

output "certificate_arn" {
  value = module.acm.certificate_arn
}

output "app_url" {
  value = "https://hello.${var.domain_name}"
}
