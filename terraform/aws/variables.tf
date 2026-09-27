variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "The AWS Region where resources will be created (e.g., us-east-1, us-west-2, eu-west-1)."
}

variable "instance_name" {
  type        = string
  default     = "ecom-app-instance"
  description = "Name tag for the EC2 VM instance."
}

variable "instance_type" {
  type        = string
  default     = "t3.medium"
  description = "EC2 instance type (t3.medium recommended: 2 vCPUs, 4 GiB RAM)."
}

variable "root_volume_size" {
  type        = number
  default     = 30
  description = "Size of the root EBS volume in Gigabytes."
}

variable "root_volume_type" {
  type        = string
  default     = "gp3"
  description = "EBS volume type for root disk (e.g., gp3, gp2)."
}

variable "key_name" {
  type        = string
  default     = ""
  description = "Optional: Name of an existing AWS EC2 Key Pair to enable SSH access. Leave empty if not using key pair."
}

variable "vpc_id" {
  type        = string
  default     = ""
  description = "Optional: VPC ID to launch instance into. If left empty, default VPC will be used."
}

variable "subnet_id" {
  type        = string
  default     = ""
  description = "Optional: Subnet ID to launch instance into. If left empty, a public subnet in default VPC will be used automatically."
}

variable "allowed_ssh_cidr" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "CIDR blocks allowed for SSH (Port 22) access."
}

variable "allowed_traffic_cidr" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "CIDR blocks allowed for Application and Observability ports."
}

variable "git_repo_url" {
  type        = string
  default     = "https://github.com/prakrit55/ecommerce-apps.git"
  description = "Git repository URL to clone on the instance."
}
