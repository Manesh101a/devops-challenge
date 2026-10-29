terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_region_validation      = true
  skip_metadata_api_check     = true
}

variable "ssh_cidr" {
  description = "The one CIDR allowed to connect over SSH, e.g. 198.51.100.10/32"
  type        = string

  validation {
    condition     = can(cidrhost(var.ssh_cidr, 0)) && var.ssh_cidr != "0.0.0.0/0" && var.ssh_cidr != "::/0"
    error_message = "Enter a valid restricted SSH CIDR; do not use a public /0 range."
  }
}

variable "ami_id" {
  description = "Example Ubuntu 24.04 AMI in us-east-1; not launched in this task"
  type        = string
  default     = "ami-0866a3c8686eaeeba"
}

locals {
  app_port = 5000
}

resource "aws_vpc" "app" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.app.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "app" {
  vpc_id = aws_vpc.app.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.app.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "app" {
  name   = "intern-task-app-sg"
  vpc_id = aws_vpc.app.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }

  ingress {
    description = "App port"
    from_port   = local.app_port
    to_port     = local.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Outbound for apt and Docker image download"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "app" {
  ami                         = var.ami_id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.app.id]

  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    dockerfile_b64 = base64encode(file("${path.module}/../../intern-task-app/Dockerfile"))
    app_b64        = base64encode(file("${path.module}/../../intern-task-app/app/app.py"))
    ssh_cidr       = var.ssh_cidr
    app_port       = local.app_port
  })

  lifecycle {
    ignore_changes = [user_data]
  }

  depends_on = [aws_route_table_association.public]
  tags = {
    Name = "intern-task-app"
  }
}

output "public_ip" {
  value = aws_instance.app.public_ip
}

output "app_port" {
  value = local.app_port
}
