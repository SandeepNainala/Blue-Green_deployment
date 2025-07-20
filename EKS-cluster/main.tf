resource "aws_vpc" "devops_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    name = "devops-vpc"
  }
  
}

resource "aws_subnet" "devops_subnet" {
  vpc_id            = aws_vpc.devops_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.devops_vpc.cidr_block, 8, count.index)
  availability_zone = element(["ap-south-1a", "ap-south-1b"], count.index)
  map_public_ip_on_launch = true

  tags = {
    name = "devops_subnet-${count.index}"
  }
}

resource "aws_internet_gateway" "devops_igw" {
  vpc_id = aws_vpc.devops_vpc.id

  tags = {
    name = "devops-igw"
  }
}

resource "aws_route_table" "devops_route_table" {
  vpc_id = aws_vpc.devops_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.devops_igw.id
  }
    tags = {
        name = "devops-route-table"
    }
}

resource "aws_route_table_association" "devops_route_table_association" {
  subnet_id      = aws_subnet.devops_subnet.id
  route_table_id = aws_route_table.devops_route_table.id
  count = length(aws_subnet.devops_subnet.*.id)
  
}

resource "aws_security_group" "devops_cluster_sg" {
  name        = "devops-sg"
  description = "Security group for devops resources"
  vpc_id      = aws_vpc.devops_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    name = "devops-cluster-sg"
  }
}

resource "aws_security_group" "devops_node_sg" {
  name        = "devops-sg"
  description = "Security group for devops resources"
  vpc_id      = aws_vpc.devops_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    name = "devops-node-sg"
  }
}

resource "aws_eks_cluster" "devops_cluster" {
  name     = "devops-cluster"
  role_arn = aws_iam_role.devops_cluster_role.arn
  version  = "1.21"

  vpc_config {
    subnet_ids         = aws_subnet.devops_subnet[*].id
    security_group_ids = [aws_security_group.devops_cluster_sg.id]
  }
  
}

resource "aws_eks_node_group" "devops_node_group" {
  cluster_name    = aws_eks_cluster.devops_cluster.name
  node_group_name = "devops-node-group"
  node_role_arn   = aws_iam_role.devops_node_group_role.arn
  subnet_ids      = aws_subnet.devops_subnet[*].id

  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 3
  }

  instance_types = ["t3.large"]

  remote_access {
    ec2_ssh_key = "devops"
    source_security_group_ids = [aws_security_group.devops_node_sg.id] 
  }

  tags = {
    name = "devops-node-group"
  }
  
}

resource "aws_iam_role" "devops_cluster_role" {
  name = "devops-cluster-role"

    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "devops_cluster_policy_attachment" {
  name       = "devops-cluster-policy-attachment"
  roles      = [aws_iam_role.devops_cluster_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  
}

resource "aws_iam_role" "devops_node_group_role" {
  name = "devops-node-group-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "devops_node_group_policy_attachment" {
  name       = "devops-node-group-policy-attachment"
  roles      = [aws_iam_role.devops_node_group_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  
}

resource "aws_iam_role_policy_attachment" "devops_node_group_cni_policy_attachment" {
  role       = aws_iam_role.devops_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  
}

resource "aws_iam_policy_attachment" "devops_node_group_registry_attachment" {
  name       = "devops-node-group-registry-attachment"
  roles      = [aws_iam_role.devops_node_group_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  
}