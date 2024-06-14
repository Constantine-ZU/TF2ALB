resource "aws_ecs_cluster" "cluster" {
  name = "cluster-pgw"
}

resource "aws_ecs_task_definition" "task" {
  family                   = "pushgateway-nginx-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = "arn:aws:iam::637423446150:role/ecsTaskExecutionRole"
  task_role_arn            = "arn:aws:iam::637423446150:role/ecsTaskRole"

  container_definitions = <<DEFINITION
[
  {
    "name": "pushgateway-nginx",
    "image": "637423446150.dkr.ecr.eu-north-1.amazonaws.com/pushgateway-nginx:latest",
    "cpu": 256,
    "memory": 512,
    "essential": true,
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80,
        "protocol": "tcp"
      },
      {
        "containerPort": 9091,
        "hostPort": 9091,
        "protocol": "tcp"
      }
    ]
  }
]
DEFINITION
}

resource "aws_ecs_service" "service" {
  name            = "pushgateway-nginx-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.subnet_10_0.id, aws_subnet.subnet_20_0.id]
    security_groups  = [aws_security_group.sg_80_433.id]
    assign_public_ip = true
  }
}
