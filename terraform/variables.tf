variable "aws_region" {
  description = "The AWS Region where resources will be provisioned"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project used for naming and tagging resources"
  type        = string
  default     = "cloud-native-devsecops"
}

variable "environment" {
  description = "Target deployment environment (e.g. dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR block for the custom VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (ALB)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (ECS Fargate tasks)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "container_port" {
  description = "Port exposed by the Node.js Express application container"
  type        = number
  default     = 3000
}

variable "app_count" {
  description = "Number of ECS task replicas to run"
  type        = number
  default     = 1
}

variable "fargate_cpu" {
  description = "Fargate CPU units (256 = 0.25 vCPU for cost minimization)"
  type        = number
  default     = 256
}

variable "fargate_memory" {
  description = "Fargate memory allocation in MB (512 MB for cost minimization)"
  type        = number
  default     = 512
}

variable "github_repo" {
  description = "GitHub repository in 'owner/repo' format for OIDC trust relationship"
  type        = string
  default     = "your-username/cloud-native-devsecops-aws"
}
