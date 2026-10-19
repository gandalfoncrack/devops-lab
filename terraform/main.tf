terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  # State is kept on the Jenkins volume so it survives between builds.
  backend "local" {
    path = "/var/jenkins_home/tfstate/lab.tfstate"
  }
}

variable "region" {
  default = "eu-north-1"
}

variable "my_ip_cidr" {
  description = "Your public IP with /32. The Jenkinsfile fills this in."
  type        = string
}

provider "aws" {
  region = var.region
}

# Latest Ubuntu 24.04 image from Canonical
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "free-tier-eligible"
    values = ["true"]
  }
}

resource "aws_key_pair" "lab" {
  key_name   = "devops-lab"
  public_key = file("${path.module}/lab-key.pub")
}

resource "aws_security_group" "lab" {
  name        = "devops-lab-sg"
  description = "SSH and the app, from my IP only"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  ingress {
    description = "App (Kubernetes NodePort)"
    from_port   = 30080
    to_port     = 30080
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "lab" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.lab.key_name
  vpc_security_group_ids = [aws_security_group.lab.id]

  # Slow down instead of paying extra if the CPU stays busy for a long time
  credit_specification {
    cpu_credits = "standard"
  }

  tags = {
    Name = "devops-lab"
  }
}

output "public_ip" {
  value = aws_instance.lab.public_ip
}
