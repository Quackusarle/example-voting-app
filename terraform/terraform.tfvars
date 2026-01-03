region              = "us-east-1"
cluster_name        = "nhom14"
cluster_version     = "1.31"
vpc_cidr            = "10.0.0.0/16"
availability_zones  = ["us-east-1a", "us-east-1b", "us-east-1c"]
node_instance_types = ["t3.large"]
node_desired_size   = 2
node_min_size       = 1
node_max_size       = 3

# AWS Academy
aws_account_id = "975050252086"
iam_role_name  = "LabRole"