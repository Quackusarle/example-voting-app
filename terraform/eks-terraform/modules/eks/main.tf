module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.31.2"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids
  cluster_endpoint_public_access = true
  create_iam_role = false
  iam_role_arn    = var.iam_role_arn
  enable_irsa = false
  manage_aws_auth_configmap = false

  create_kms_key              = false
  create_cloudwatch_log_group = false
  eks_managed_node_groups = {
    main = {
      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size
      instance_types = var.node_instance_types
      create_iam_role = false
      iam_role_arn    = var.iam_role_arn
    }
  }

  cluster_addons = {
    coredns    = { most_recent = true }
    kube-proxy = { most_recent = true }
    vpc-cni    = { most_recent = true }
  }
}