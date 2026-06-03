# -------- Networking --------

module "networking" {
  source = "../../modules/networking"

  name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
  availability_zones = local.azs
  tags = local.common_tags
}

# -------- EKS --------

module "eks" {
  source = "../../modules/eks"

  project_name        = var.project_name
  environment         = var.environment
  cluster_version     = var.cluster_version
  eks_nodes_security_group_id = module.securitygroups.eks_nodes_security_group_id
  vpc_id = module.networking.vpc_id
  private_subnet_ids  = module.networking.private_subnet_ids
  public_subnet_ids   = module.networking.public_subnet_ids
  access_cidrs = var.access_cidrs

  node_desired_size   = 3
  node_min_size       = 3
  node_max_size       = 6
  node_instance_types = ["t3.medium"]

  tags = local.common_tags
}

# -------- ECR --------

module "ecr" {
  source = "../../modules/ecr"

  repository_name      = "${var.project_name}-webserver"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = true  # dev only

  tags = local.common_tags
}

# -------- RDS --------

module "rds" {
  source = "../../modules/rds"

  identifier                 = "${var.project_name}-${var.environment}"
  subnet_ids                 = module.networking.private_subnet_ids
  vpc_id                     = module.networking.vpc_id
  allowed_security_group_ids = [module.securitygroups.eks_nodes_security_group_id]

  multi_az            = true
  deletion_protection = false   # dev environment only 
  skip_final_snapshot = true    # dev environment only

  tags = local.common_tags
}

# -------- DNS + ACM --------

module "dns_certs" {
  source = "../../modules/dns_certs"

  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  hosted_zone_id            = var.hosted_zone_id
  create_route53_zone       = false

  tags = local.common_tags
}

#-------- Security Groups --------
module "securitygroups" {
  source = "../../modules/securitygroups"

  project_name = var.project_name
  environment  = var.environment
  vpc_id      = module.networking.vpc_id

  tags = local.common_tags
}

#------------ local file for AWS LBC values ------------

resource "local_file" "aws_lbc_values" {
  filename = "${path.module}/../../../argocd/values/aws-load-balancer-controller-values.yaml"
  content  = <<-EOT
    clusterName: ${module.eks.cluster_name}
    region: ${var.region}
    vpcId: ${module.networking.vpc_id}
    serviceAccount:
      create: true
      name: aws-load-balancer-controller
      annotations:
        eks.amazonaws.com/role-arn: ${module.eks.aws_load_balancer_controller_role_arn}
  EOT
}