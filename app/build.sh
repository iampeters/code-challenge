#!/bin/bash

# This script is used to build, tag and push the application from source.

# Build the application
echo "Building the application..."
docker build -t 823343520581.dkr.ecr.eu-west-1.amazonaws.com/ceros-ski:latest .

# Tag the image
# echo "Tagging the image..."
# docker tag ceros-ski:latest 823343520581.dkr.ecr.eu-west-1.amazonaws.com/ceros-ski:latest

# Login to ECR
echo "Logging into ECR..."
aws ecr get-login-password --region eu-west-1 --profile 78 | docker login --username AWS --password-stdin 823343520581.dkr.ecr.eu-west-1.amazonaws.com

# Push the image to ECR
echo "Pushing the image to ECR..."
docker push 823343520581.dkr.ecr.eu-west-1.amazonaws.com/ceros-ski:latest

echo "Build and push complete"