/******************************************************************************
* ECS Cluster
*
* Create ECS Cluster and its supporting services, in this case EC2 instances in
* and Autoscaling group.
*
* *****************************************************************************/

/**
* The ECS Cluster and its services and task groups. 
*
* The ECS Cluster has no dependencies, but will be referenced in the launch
* configuration, may as well define it first for clarity's sake.
*/

resource "aws_ecs_cluster" "cluster" {
  name = "ceros-ski-${var.environment}"
  
  tags = {
    Application = "ceros-ski"
    Environment = var.environment
    Resource    = "modules.ecs.cluster.aws_ecs_cluster.cluster"
  }

  depends_on = [
    aws_vpc.main_vpc,
  ]
}


/**
* Create the task definition for the ceros-ski backend, in this case a thin
* wrapper around the container definition.
*/
resource "aws_ecs_task_definition" "backend" {
  family       = "ceros-ski-${var.environment}-backend"
  network_mode = "bridge"

  container_definitions = <<EOF
[
  {
    "name": "ceros-ski",
    "image": "${var.repository_url}:latest",
    "environment": [
      {
        "name": "PORT",
        "value": "80"
      }
    ],
    "cpu": 512,
    "memoryReservation": 512,
    "essential": true,
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80,
        "protocol": "tcp"
      }
    ]
  }
]
EOF

  tags = {
    Application = "ceros-ski"
    Environment = var.environment
    Name        = "ceros-ski-${var.environment}-backend"
    Resource    = "modules.environment.aws_ecs_task_definition.backend"
  }
}

/**
* This role is automatically created by ECS the first time we try to use an ECS
* Cluster.  By the time we attempt to use it, it should exist.  However, there
* is a possible TECHDEBT race condition here.  I'm hoping terraform is smart
* enough to handle this - but I don't know that for a fact. By the time I tried
* to use it, it already existed.
*/
data "aws_iam_role" "ecs_service" {
  name = "AWSServiceRoleForECS"
}

/**
* Create the ECS Service that will wrap the task definition.  Used primarily to
* define the connections to the load balancer and the placement strategies and
* constraints on the tasks.
*/
resource "aws_ecs_service" "backend" {
  name            = "ceros-ski-${var.environment}-backend"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.backend.arn

  iam_role = data.aws_iam_role.ecs_service.arn

  launch_type = "EC2"

  desired_count                      = 2
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 100

  load_balancer {
    container_name   = "ceros-ski"
    container_port   = 80
    target_group_arn = aws_alb_target_group.ceros-ski-tg.arn
  }

  tags = {
    Application = "ceros-ski"
    Environment = var.environment
    Resource    = "modules.environment.aws_ecs_service.backend"
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_agent,
    aws_alb_listener.ceros-ski-listener
  ]
}

