variable "aws_region" {
  description = "AWS region"
  default     = "eu-west-1"
}

variable "name" {
  description = "Unique name of the deployment"
}

variable "vault_public_url" {
  description = "Vault Address"
}

variable "vault_username" {
  description = "Username to checkout AWS Provider credentials from Vault"
}

variable "vault_password" {
  description = "Password to checkout credentials"
}

variable "vault_namespace" {
  default = "admin"
}

variable "instance_type" {
  description = "instance size to be used for worker nodes"
  default     = "t2.small"
}

variable "pub_key" {
  description = "the public key to be used to access the bastion host and ansible nodes"
  default     = "joestack"
}

variable "network_address_space" {
  description = "CIDR for this deployment"
  default     = "192.168.0.0/16"
}

variable "ami_id" {
  default = "ami-0f29c8402f8cce65c"
}