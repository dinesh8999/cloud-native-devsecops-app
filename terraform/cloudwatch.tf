# CloudWatch Log Group for ECS Container stdout / stderr
resource "aws_cloudwatch_log_group" "ecs_app" {
  name              = "/ecs/${var.project_name}-app"
  retention_in_days = 7 # 7 days retention to avoid unnecessary CloudWatch storage charges

  tags = {
    Name = "${var.project_name}-log-group"
  }
}

# CloudWatch High CPU Utilization Alarm (> 80% for 2 consecutive 1-minute periods)
resource "aws_cloudwatch_metric_alarm" "ecs_high_cpu" {
  alarm_name          = "${var.project_name}-high-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Triggers if ECS Fargate container CPU utilization exceeds 80%"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.main.name
  }

  tags = {
    Name = "${var.project_name}-cpu-alarm"
  }
}

# CloudWatch High Memory Utilization Alarm (> 80% for 2 consecutive 1-minute periods)
resource "aws_cloudwatch_metric_alarm" "ecs_high_memory" {
  alarm_name          = "${var.project_name}-high-memory-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Triggers if ECS Fargate container Memory utilization exceeds 80%"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.main.name
  }

  tags = {
    Name = "${var.project_name}-memory-alarm"
  }
}
