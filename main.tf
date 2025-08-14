# Will add resources in the next phases
############################
# Phase 2 — Networking
############################

# Pick first two available AZs in the chosen region
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
  # Map AZ -> index (0,1) to build unique subnet CIDRs
  az_map = { for idx, az in local.azs : az => idx }
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "${var.project}-vpc"
    Project = var.project
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${var.project}-igw"
    Project = var.project
  }
}

# Two public subnets across two AZs, each with public IP on launch
resource "aws_subnet" "public" {
  for_each = local.az_map

  vpc_id                  = aws_vpc.main.id
  availability_zone       = each.key
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, each.value) # 10.0.0.0/24, 10.0.1.0/24
  map_public_ip_on_launch = true

  tags = {
    Name    = "${var.project}-public-${each.value + 1}"
    Project = var.project
    Tier    = "public"
    AZ      = each.key
  }
}

# Route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${var.project}-rt-public"
    Project = var.project
  }
}

# Default route to the Internet via IGW
resource "aws_route" "public_inet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Associate both public subnets with the public route table
resource "aws_route_table_association" "public_assoc" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

############################
# Phase 3 — SG + EC2 + Nginx
############################

# Find a recent Ubuntu 22.04 LTS AMI
# Amazon Linux 2023 (x86_64) — official Amazon owner

# data "aws_ami" "al2023" {
#   most_recent = true
#   owners      = ["137112412989"] # Amazon

#   filter {
#     name   = "name"
#     values = ["ami-0de716d6197524dd9"]
#   }
#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }
#   filter {
#     name   = "root-device-type"
#     values = ["ebs"]
#   }
# }

# Security Group: allow HTTP in, all egress out
resource "aws_security_group" "web_sg" {
  name        = "${var.project}-web-sg"
  description = "Allow HTTP from anywhere; all egress"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project}-web-sg"
    Project = var.project
  }
}

# User data to install and start Nginx, and serve a basic page
locals {
  nginx_user_data = <<-EOT
    #!/bin/bash -xe
    # AL2023 uses dnf; AL2 uses yum — try dnf first, then yum
    if command -v dnf >/dev/null 2>&1; then
      dnf -y update
      dnf -y install nginx
    else
      yum -y update
      yum -y install nginx
    fi

    systemctl enable nginx
    systemctl start nginx

    # Default doc root on Amazon Linux Nginx
    cat > /usr/share/nginx/html/index.html <<'HTML'
    <!doctype html>
    <html>
      <head><title>Hello Nginx</title></head>
      <body style="font-family:system-ui; margin: 40px;">
        <h1>Hello from Terraform + Nginx </h1>
        <p>OS: Amazon Linux</p>
      </body>
    </html>
    HTML

    systemctl restart nginx
  EOT
}


# Launch one EC2 in the first public subnet (explicit public IP)
resource "aws_instance" "web" {
  ami                         = "ami-0de716d6197524dd9"
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public[local.azs[0]].id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  user_data                   = local.nginx_user_data
  user_data_replace_on_change = true

  tags = {
    Name    = "${var.project}-web"
    Project = var.project
  }
}
