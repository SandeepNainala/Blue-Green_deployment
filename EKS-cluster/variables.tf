variable "ssh_key_name" {
  description = "The name of the SSH key pair to use for EC2 instances in the EKS cluster."
  type        = string
  default     = "devops"
  
}