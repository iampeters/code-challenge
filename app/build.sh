#!/bin/bash

REPO_URL="***"
REGION="***"
PROFILE="***"

# This script is used to build, tag and push the application from source.

# Build the application
echo "Building the application..."
docker build -t $REPO_URL/ceros-ski:latest .

# Login to ECR
echo "Logging into ECR..."
aws ecr get-login-password --region $REGION --profile $PROFILE | docker login --username AWS --password-stdin $REPO_URL

# Push the image to ECR
echo "Pushing the image to ECR..."
docker push $REPO_URL/ceros-ski:latest

echo "Build and push complete"