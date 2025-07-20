output "cluster_id" {
  description = "The ID of the EKS cluster."
  value       = aws_eks_cluster.devops_cluster.id
}

output "node_group_id" {
  description = "The ID of the EKS node group."
  value       = aws_eks_node_group.devops_node_group.id
}

output "vpc_id" {
  description = "The vpc id."
  value       = aws_vpc.devops_vpc.id
}

output "subnet_ids" {
  description = "The IDs of the subnets in the EKS cluster."
  value       = aws_subnet.devops_subnet[*].id
}