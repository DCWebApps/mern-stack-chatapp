# VPC Configuration
resource "aws_vpc" "chat_app_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "chat-app-vpc-prod"
    Environment = "production"
  }
}

# Public Subnets
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.chat_app_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = element(var.availability_zones, 0)
  map_public_ip_on_launch = true

  tags = {
    Name = "chat-app-public-subnet-1"
    Environment = "production"
    "kubernetes.io/cluster/chat-app-eks-prod" = "shared"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.chat_app_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = element(var.availability_zones, 1)
  map_public_ip_on_launch = true

  tags = {
    Name = "chat-app-public-subnet-2"
    Environment = "production"
    "kubernetes.io/cluster/chat-app-eks-prod" = "shared"
    "kubernetes.io/role/elb" = "1"
  }
}

# Private Subnets
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.chat_app_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = element(var.availability_zones, 0)

  tags = {
    Name = "chat-app-private-subnet-1"
    Environment = "production"
    "kubernetes.io/cluster/chat-app-eks-prod" = "shared"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.chat_app_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = element(var.availability_zones, 1)

  tags = {
    Name = "chat-app-private-subnet-2"
    Environment = "production"
    "kubernetes.io/cluster/chat-app-eks-prod" = "shared"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "chat_app_igw" {
  vpc_id = aws_vpc.chat_app_vpc.id

  tags = {
    Name = "chat-app-igw-prod"
    Environment = "production"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "chat-app-nat-eip-prod"
    Environment = "production"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "chat_app_nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id

  tags = {
    Name = "chat-app-nat-prod"
    Environment = "production"
  }

  depends_on = [aws_internet_gateway.chat_app_igw]
}

# Route Tables
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.chat_app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.chat_app_igw.id
  }

  tags = {
    Name = "chat-app-public-route-table-prod"
    Environment = "production"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.chat_app_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.chat_app_nat.id
  }

  tags = {
    Name = "chat-app-private-route-table-prod"
    Environment = "production"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public_subnet_1_association" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_2_association" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_subnet_1_association" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_subnet_2_association" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_route_table.id
}

# Security Groups
resource "aws_security_group" "eks_cluster_sg" {
  name        = "chat-app-eks-cluster-sg"
  description = "Security group for EKS cluster"
  vpc_id      = aws_vpc.chat_app_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "chat-app-eks-cluster-sg-prod"
    Environment = "production"
  }
}

resource "aws_security_group" "eks_nodes_sg" {
  name        = "chat-app-eks-nodes-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = aws_vpc.chat_app_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [aws_security_group.eks_cluster_sg.id]
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "chat-app-eks-nodes-sg-prod"
    Environment = "production"
  }
}

resource "aws_security_group" "nlb_sg" {
  name        = "chat-app-nlb-sg"
  description = "Security group for Network Load Balancer"
  vpc_id      = aws_vpc.chat_app_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "chat-app-nlb-sg-prod"
    Environment = "production"
  }
}