# Architecture

The infrastructure for the Ceros-ski game is constructed in two, interdependent
pieces that must be deployed separately.  The first is the ECR repository that
will store the built docker images for the ceros-ski container.  The second is
the ECS Cluster that will run those docker images.

The ECS Cluster is currently built to use an EC2 Autoscaling group that sits in
a private VPC in a single availability zone.  It has a single service and a
single task definition.

The ECR Repository is defined in `infrastructure/repositories`.

The ECS Cluster is defined in `infrastructure/environments`.

All are currently configured to use local state.

## Dockerfile

The dockerfile contains a multi-stage build to avoid source code exposure.
This makes the image size small and lightweight only containing the built artifacts in the `/dist` directory.

The build command was combined with the tag command. `docker build -t ***.dkr.ecr.eu-west-1.amazonaws.com/ceros-ski:latest .` This was done this way to avoid having two separate images after the build is done.

The build script `./app/build.sh` can be used in a CI pipeline to automatically build, tag and push the image.

## Repository

The `infrastructure/repository` directory contains information that will create ECR repository on AWS when applied.

You will need to inspect the `variables.tf` file to provide the necessary variables.

## ECS cluster

The ECS cluster and its dependencies are defined in `infrastructure/environments`.

The cluster is made up of the following resources;

- A `bastion host` with configurations defined in `infrastructure/environments/ec2.tf`. This host is used for SSH access to the ECS instance.

- Application loadbalancer with configs defined in `infrastructure/environments/alb.tf`. This is used to expose the url of the application running in the ECS cluster.
