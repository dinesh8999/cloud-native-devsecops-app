# Application runtime secret managed in AWS Secrets Manager
resource "aws_secretsmanager_secret" "app_secret" {
  name                    = "${var.project_name}-app-secret-${var.environment}"
  description             = "Runtime configuration and secret keys for DevSecOps application"
  recovery_window_in_days = 0 # Immediate deletion upon terraform destroy for fast lab tear-down

  tags = {
    Name = "${var.project_name}-secret"
  }
}

# Example secret key-value payload securely injected into ECS Fargate
resource "aws_secretsmanager_secret_version" "app_secret_value" {
  secret_id = aws_secretsmanager_secret.app_secret.id
  secret_string = jsonencode({
    API_KEY     = "production-encrypted-key-sample-12345"
    DB_PASSWORD = "super-secret-vault-password-67890"
  })
}
