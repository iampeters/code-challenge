# Usage

There are two separate infrastructures defined here.  The first defines the ECR
Repository and the second the actual ECS Environment.  The ECR Repository must
be created first, and the `repository_url` output taken and used as an input
variable for the ECS Environment.

### Creating the ECR Repository

To create the ECR Repository, you'll need to first initialize it with a .tfvars
file defining the credentials you want to use to access AWS and the region
you'd like to deploy to.

You can inspect `infrastructure/repositories/variables.tf` for a list of
required variables and attendant descriptions.  An example is shown below.

Example `infrastructure/repositories/terraform.tfvars`:
```
// Path to your .aws/credentials file.
aws_credentials_file = "/Users/malcolmreynolds/.aws/credentials"

// The name of the profile from your aws credentials file you'd like to use.
aws_profile = "serenity"

// The region we'll create the repository in
aws_region = "us-east-1"
```

Once you've created your tfvars file, you can run `terraform init` to
initialize terraform for this infrastructure.  You'll need to ensure you have
Terraform version 0.14+ installed.  Then you can run `terraform apply` to
create it.

After terraform has run it will output the repository URL, which you will need
to push an initial docker image and to give to the ECS stack to pull the image.

### Pushing an Initial Docker Image

Before you can build the ECS infrastructure, you'll need to push an initial
docker image to the ECR repository.  The ECS infrastructure will pull the
`latest` tag, so you'll want to push that tag to the repository.

From the root project directory.
```
# Go to the app directory and build the docker image.
$ cd app

# Build the docker image.
$ docker build -t ceros-ski .

# Tag the docker image.
$ docker tag <repository_url>/ceros-ski:latest

# Login to ECR.  
$ aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <repository_url> 

# Push the docker image to ECR.
$ docker push <repository_url>/ceros-ski:latest
```

### Building the ECS Stack

Once you've built the repo and push the initial docker image, then you need to
build the ECS Stack.  Go to `infrastructure/environments`.  Run `terraform init` and
then populate the `terraform.tfvars` file.

Example `infrastructure/environments/terraform.tfvars`:
```
aws_credentials_file = "/Users/malcolmreynolds/.aws/credentials"
aws_profile = "serenity"
aws_region = "us-east-1"
repository_url = "<account #>.dkr.ecr.us-east-1.amazonaws.com/ceros-ski"
public_key_path = "/Users/malcolmreynolds/.ssh/id_rsa.pub"
```

Once you've initialized the infrastructure and created your .tfvars file, you
can use `terraform apply` to create the ECS infrastructure.  Currently, the
infrastructure is non-functional.  We leave it as an exercise for the reader to
amend that.

===========================================================================================

## Ceros challenge

### Create the ECR repository

```bash
# Change directory from the root directory to `infrastructure/repositories`.Run the command below

cd infrastructure/repositories
```

```bash
# Update with `terraform.tfvars` file with the correct value of the provided variables
# Plan the infrastructure by running the following command

terraform plan --var-file terraform.tfvars \
    -out terraform.tfplan.d/terraform.tfplan \
    -state terraform.tfstate \
    -state-out terraform.tfstate
```

```bash
# If all goes well, apply the plan by running the following command
# The repository_url will be outputted on the console.
# Copy it out for later use in the build script

terraform apply "terraform.tfplan.d/terraform.tfplan"
```


### Build and push the image

The build script is defined in `app/build.sh` in the root directory.

Update the environment variable value `REPO_URL` with the `repository_url` outputted from the ECR repository.

To build and push the image run

```bash
./build.sh
```

### ECS cluster deployment

Once the app image has been pushed to ECR, change directory to `infrastructure/environments`.

```bash
# From the current directory which should be `app`, run this command
cd ../infrastructure/environments
```

#### Generate a keypair used to SSH into the bastion host.

```bash
ssh-keygen -m PEM
```

Follow the prompt and name the keypair output file `ceros`.
Add the generated `ceros.pub` file which should be in `infrastructure/environments` to `public_key_path` variable in  `terraform.tsvars` file
Update the rest of the variables defined in `terraform.tfvars` file with the correct values.

#### Plan the infrastructure

```bash
terraform plan --var-file terraform.tfvars \
    -out terraform.tfplan.d/terraform.tfplan \
    -state terraform.tfstate \
    -state-out terraform.tfstate
```

#### Apply the plan

```bash
terraform apply "terraform.tfplan.d/terraform.tfplan"
```

After the ECS cluster and its components have been created successfully, the url to access the application on the browser will be outputted in console.

### Destroy the infrastructure

To destroy the infrastructure, run the command

```bash
terraform destroy --var-file terraform.tfvars 
```