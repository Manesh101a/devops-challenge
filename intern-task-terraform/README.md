# Intern Task – Terraform

## Overview

This project uses Terraform to configure an AWS EC2 instance to run the Docker application from `intern-task-app` on port **5000**.

## Infrastructure

Terraform defines:
- VPC and public subnet
- Internet Gateway and route table
- Security Group (SSH restricted to a specific CIDR, app port 5000 open)
- EC2 instance with a public IP

## EC2 Setup

The `user_data` script:
- Creates a non-root user with passwordless sudo
- Installs Docker and Git
- Clones the application repository and builds its Docker image
- Runs the container using systemd so it restarts after reboot
- Configures UFW firewall rules

## Preventing EC2 Replacement

```hcl
lifecycle {
  ignore_changes = [user_data]
}
```

This prevents Terraform from modifying the instance when `user_data` changes. Applying bootstrap changes requires intentionally recreating the instance.

## Run Locally

```bash
cd intern-task-terraform/terraform

terraform fmt -check
terraform init
terraform validate
terraform plan -var="ssh_cidr=198.51.100.10/32"
```

Set fake AWS credentials before running the plan:

```bash
export AWS_ACCESS_KEY_ID=fake
export AWS_SECRET_ACCESS_KEY=fake
export AWS_DEFAULT_REGION=us-east-1
```

## CI Pipeline Fixes

Updated `.github/workflows/intern-task-terraform-ci.yml` to:
- Run commands from the correct Terraform directory
- Add `terraform init` before validation
- Pass the required SSH CIDR variable during planning
- Trigger CI when relevant files change

## Note

No real AWS resources are deployed. The task only requires `terraform validate` and `terraform plan`.