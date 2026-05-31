output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_ca_certificate" {
  value = module.eks.cluster_certificate_authority
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "node_security_group_id" {
  value = module.securitygroups.eks_nodes_security_group_id
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
  value = module.dns_certs.certificate_arn
}

output "app_url" {
  value = "https://hello.${var.domain_name}"
}

output "rds_credentials_secret_arn" {
  value       = module.rds.db_credentials_secret_arn
}

output "rds_endpoint_address" {
  value = module.rds.db_instance_address
}

output "rds_port" {
  value = module.rds.db_instance_port
}

output "rds_db_name" {
  value = module.rds.db_name
}

output "rds_master_username" {
  value = module.rds.db_master_username
}