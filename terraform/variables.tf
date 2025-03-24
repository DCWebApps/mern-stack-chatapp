variable "region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets_cidr" {
  description = "CIDR blocks for public subnets (must have 2 entries)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets_cidr" {
  description = "CIDR blocks for private subnets (must have 2 entries)"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "availability_zones" {
  description = "Availability zones for subnets (must have 2 entries)"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "instance_type" {
  description = "EC2 instance type for EKS nodes"
  type        = string
  default     = "t3.medium"
}

variable "user_ip" {
  description = "Your public IP for SSH access (format: x.x.x.x/32)"
  type        = string
  default     = "YOUR_IP/32"  # Replace with your actual IP
}

variable "ssh_key_name" {
  description = "Name of the EC2 SSH key pair"
  type        = string
  default     = "eks-node-key"  # Replace with your EC2 key pair name
}

variable "node_group_size" {
  description = "Desired size of the EKS node group"
  type        = number
  default     = 2
}