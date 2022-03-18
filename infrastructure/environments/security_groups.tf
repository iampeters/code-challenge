
/**
* A security group for the instances in the autoscaling group allowing HTTP
* ingress.  With out this the Target Group won't be able to reach the instances
* (and thus the containers) and the health checks will fail, causing the
* instances to be deregistered.
*/
resource "aws_security_group" "autoscaling_group" {
  name        = "ceros-ski-${var.environment}-autoscaling_group"
  description = "Security Group for the Autoscaling group which provides the instances for the ECS Cluster."
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "HTTP Ingress"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Application = "ceros-ski"
    Environment = var.environment
    Resource    = "modules.ecs.cluster.aws_security_group.autoscaling_group"
  }
}

/**
* A security group for alb.
*/
resource "aws_security_group" "alb-sg" {
  name        = "testapp-load-balancer-security-group"
  description = "controls access to the ALB"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "HTTP Ingress"
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

/**
* A security group to allow SSH access into our bastion instance.
*/
resource "aws_security_group" "bastion" {
  name = "bastion-security-group-eu-west-1a"
  vpc_id = aws_vpc.main_vpc.id 

  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress {
    protocol = -1
    from_port = 0
    to_port = 0
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  tags = {
    Application = "ceros-ski" 
    Environment = var.environment 
    Resource = "modules.availability_zone.aws_security_group.bastion"
  }

}