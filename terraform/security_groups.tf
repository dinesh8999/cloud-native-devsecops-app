# Security Group for Public Application Load Balancer
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Controls incoming HTTP traffic to the Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  # Allow incoming HTTP traffic from anywhere on the internet
  ingress {
    description = "Allow inbound HTTP from internet"
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow outgoing traffic to forward requests to ECS tasks
  egress {
    description = "Allow all outbound traffic"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# Security Group for Private ECS Fargate Container Tasks
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project_name}-ecs-tasks-sg"
  description = "Allows inbound traffic ONLY from ALB security group on container port"
  vpc_id      = aws_vpc.main.id

  # Least-privilege ingress: Only accept traffic originating from ALB Security Group
  ingress {
    description     = "Allow inbound HTTP traffic strictly from ALB"
    protocol        = "tcp"
    from_port       = var.container_port
    to_port         = var.container_port
    security_groups = [aws_security_group.alb.id]
  }

  # Allow egress for pulling container images (ECR) and sending logs (CloudWatch)
  egress {
    description = "Allow outbound to internet/VPC endpoints"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ecs-tasks-sg"
  }
}
