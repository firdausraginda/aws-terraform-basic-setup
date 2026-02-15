## Step 1 — Install AWS CLI

```bash
# macOS
brew install awscli

# verify
aws --version
```

## Step 2 — Create IAM User for Terraform

1. Go to AWS Console → IAM → Users → Create User
2. Name it `terraform-user`
3. Attach policy: search for exactly **`ReadOnlyAccess`** (not the service-specific ones like AIOps, Alexa, etc.)
    - Or use `AmazonEC2ReadOnlyAccess` if you only need EC2
    - Later switch to `AdministratorAccess` when you want Terraform to create/modify resources
4. Create **Access Key** → choose "CLI" → save the key and secret

## Step 3 — Configure AWS CLI

```bash
aws configure
# AWS Access Key ID: <paste your key>
# AWS Secret Access Key: <paste your secret>
# Default region: <your region, e.g. ap-southeast-1>
# Default output format: json
```

Verify:

```bash
aws ec2 describe-instances
```

## Step 4 — Install Terraform

```bash
# macOS
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# verify
terraform -version
```

## Step 5 — Install Terraformer

```bash
brew install terraformer

# verify
terraformer -v
```

## Step 6 — Create Project Folder

```bash
mkdir ~/terraform-aws && cd ~/terraform-aws
```

## Step 7 — Create Provider Config

Create `versions.tf`:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"  # change to your region
}
```

## Step 8 — Initialize Terraform

```bash
terraform init
```

## Step 9 — Import Existing EC2 with Terraformer

```bash
terraformer import aws \
  --resources=ec2_instance \
  --regions=ap-southeast-1 \
  --profile=default
```

Generated files:

```
generated/
└── aws/
    └── ec2_instance/
        ├── ec2_instance.tf       ← your EC2 config
        ├── outputs.tf
        ├── provider.tf
        └── terraform.tfstate     ← state file
```

## Step 10 — Organize Generated Files by Service

Create a service folder and clean up the generated resource:

```bash
mkdir ec2
```

Move and clean up the generated config into `ec2/main.tf` — rename the resource to something readable, remove redundant/default attributes:

```hcl
# ec2/main.tf
resource "aws_instance" "airflow_test" {
  ami                         = "ami-08d59269edddde222"
  instance_type               = "t3.small"
  subnet_id                   = "subnet-xxxxx"
  vpc_security_group_ids      = ["sg-xxxxx"]
  # ... other attributes
}
```

Create `ec2/outputs.tf`:

```hcl
output "airflow_test_instance_id" {
  value = aws_instance.airflow_test.id
}
```

## Step 11 — Wire the Module in Root main.tf

Create `main.tf` at the project root to reference the service module:

```hcl
module "ec2" {
  source = "./ec2"
}
```

## Step 12 — Re-initialize and Import State

```bash
# Register the new module
terraform init

# Link the existing AWS resource to Terraform state
terraform import module.ec2.aws_instance.airflow_test i-xxxxxxxxxxxx
```

## Step 13 — Verify No Drift

```bash
terraform plan
```

Expected output:

```
No changes. Your infrastructure matches the configuration.
```

## Step 14 — Import More Resources (Optional)

```bash
terraformer import aws \
  --resources=ec2_instance,vpc,subnet,sg \
  --regions=ap-southeast-1
```

Then repeat the same pattern — create service folders (`vpc/`, `subnet/`, `sg/`), clean up configs, wire modules in `main.tf`, and import state:

```bash
# Re-initialize to register new modules
terraform init

# Import each resource
terraform import module.vpc.aws_vpc.default vpc-xxxxxxxxxxxx
terraform import module.subnet.aws_subnet.default_ap_southeast_1c subnet-xxxxxxxxxxxx
terraform import module.sg.aws_security_group.launch_wizard_1 sg-xxxxxxxxxxxx

# Verify
terraform plan
```

Modules that depend on other modules receive values via variables:

```hcl
# main.tf
module "vpc" {
  source = "./vpc"
}

module "subnet" {
  source         = "./subnet"
  default_vpc_id = module.vpc.default_vpc_id
}

module "sg" {
  source         = "./sg"
  default_vpc_id = module.vpc.default_vpc_id
}

module "ec2" {
  source = "./ec2"
}
```

## Step 15 — Clean Up

Remove the `generated/` folder after you've moved everything:

```bash
rm -rf generated
```

## Useful Commands

| Command | Description |
| --- | --- |
| `terraform init` | Initialize project, download providers |
| `terraform plan` | Preview changes before applying |
| `terraform apply` | Apply changes to AWS |
| `terraform destroy` | Remove all Terraform-managed resources |
| `terraform fmt` | Auto-format .tf files |
| `terraform state list` | List all resources Terraform manages |
| `terraform state rm <resource>` | Remove a resource from state without destroying it |
| `terraform import <resource> <id>` | Link an existing AWS resource to Terraform state |