output "vpc_id" {
  description = "The ID of the custom VPC"
  value       = aws_vpc.main.id
}

output "public_subnets" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnets" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "ecr_repository_url" {
  description = "URL of the Amazon ECR repository for Docker images"
  value       = aws_ecr_repository.app.repository_url
}

output "alb_dns_name" {
  description = "Public URL (DNS Name) of the Application Load Balancer to access the live app"
  value       = aws_lb.main.dns_name
}

output "ecs_cluster_name" {
  description = "Name of the ECS Cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "Name of the ECS Service"
  value       = aws_ecs_service.main.name
}

output "github_actions_role_arn" {
  description = "ARN of the IAM Role for GitHub Actions OIDC Authentication"
  value       = aws_iam_role.github_actions_oidc.arn
}

output "cloudwatch_log_group" {
  description = "CloudWatch Log Group name for container logs"
  value       = aws_cloudwatch_log_group.ecs_app.name
}
