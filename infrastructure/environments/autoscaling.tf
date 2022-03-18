
/*******************************************************************************
* AutoScaling Group
*
* The autoscaling group that will generate the instances used by the ECS
* cluster.
*
********************************************************************************/

/**
* The IAM policy needed by the ecs agent to allow it to manage the instances
* that back the cluster.  This is the terraform structure that defines the
* policy.
*/
data "aws_iam_policy_document" "ecs_agent" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeTags",
      "ecs:CreateCluster",
      "ecs:DeregisterContainerInstance",
      "ecs:DiscoverPollEndpoint",
      "ecs:Poll",
      "ecs:RegisterContainerInstance",
      "ecs:StartTelemetrySession",
      "ecs:UpdateContainerInstancesState",
      "ecs:Submit*",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "*"
    ]
  }
}

/**
* The policy resource itself.  Uses the policy document defined above.
*/
resource "aws_iam_policy" "ecs_agent" {
  name        = "ceros-ski-ecs-agent-policy"
  path        = "/"
  description = "Access policy for the EC2 instances backing the ECS cluster."

  policy = data.aws_iam_policy_document.ecs_agent.json
}

/**
* A policy document defining the assume role policy for the IAM role below.
* This is required.
*/
data "aws_iam_policy_document" "ecs_agent_assume_role_policy" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }

}

/**
* The IAM role that will be used by the instances that back the ECS Cluster.
*/
resource "aws_iam_role" "ecs_agent" {
  name = "ceros-ski-ecs-agent"
  path = "/"

  assume_role_policy = data.aws_iam_policy_document.ecs_agent_assume_role_policy.json
}

/**
* Attatch the ecs_agent policy to the role.  The assume_role policy is attached
* above in the role itself.
*/
resource "aws_iam_role_policy_attachment" "ecs_agent" {
  role       = aws_iam_role.ecs_agent.name
  policy_arn = aws_iam_policy.ecs_agent.arn
}

/**
* The Instance Profile that associates the IAM resources we just finished
* defining with the launch configuration.
*/
resource "aws_iam_instance_profile" "ecs_agent" {
  name = "ceros-ski-ecs-agent"
  role = aws_iam_role.ecs_agent.name
}

/** 
* This parameter contains the AMI ID of the ECS Optimized version of Amazon
* Linux 2 maintained by AWS.  We'll use it to launch the instances that back
* our ECS cluster.
*/
data "aws_ssm_parameter" "cluster_ami_id" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

/**
* The launch configuration for the autoscaling group that backs our cluster.  
*/
resource "aws_launch_configuration" "cluster" {
  name                 = "ceros-ski-${var.environment}-cluster"
  image_id             = data.aws_ssm_parameter.cluster_ami_id.value
  instance_type        = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.ecs_agent.name
  security_groups      = [aws_security_group.autoscaling_group.id]

  // Register our EC2 instances with the correct ECS cluster.
  user_data = <<EOF
#!/bin/bash
echo "ECS_CLUSTER=${aws_ecs_cluster.cluster.name}" >> /etc/ecs/ecs.config
EOF
}

/**
* The autoscaling group that backs our ECS cluster.
*/
resource "aws_autoscaling_group" "cluster" {
  name             = "ceros-ski-${var.environment}-cluster"
  min_size         = 1
  max_size         = 4
  desired_capacity = 2

  vpc_zone_identifier  = aws_subnet.public_subnet.*.id
  launch_configuration = aws_launch_configuration.cluster.name

  tag {
    key                 = "Application"
    value               = "ceros-ski"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "Resource"
    value               = "modules.ecs.cluster.aws_autoscaling_group.cluster"
    propagate_at_launch = true
  }

  depends_on = [
    aws_vpc.main_vpc,
  ]
}
