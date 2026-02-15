resource "aws_ecs_cluster" "main" {
  name = "dummy-etl-cluster"
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/dummy-etl"
  retention_in_days = 7
}

resource "aws_security_group" "ecs_task" {
  name        = "ecs-task-sg"
  description = "Security group for ECS Fargate tasks"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_task_definition" "etl" {
  family                   = "dummy-etl-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([{
    name      = "etl"
    image     = "${var.ecr_repository_url}:latest"
    essential = true

    environment = [{
      name  = "S3_BUCKET"
      value = var.s3_bucket_name
    }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
        "awslogs-region"        = "ap-southeast-1"
        "awslogs-stream-prefix" = "etl"
      }
    }
  }])
}
