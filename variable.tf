variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  # Change this if you prefer another region (e.g., ca-central-1)
  default = "us-east-1"
}

variable "project" {
  description = "Short name to tag resources."
  type        = string
  default     = "vpc-ec2-nginx"
}

variable "vpc_cidr" {
  description = "VPC CIDR range"
  type        = string
  default     = "10.0.0.0/16"
}
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  # Free Tier: usually t2.micro (some regions use t3.micro)
  default     = "t2.micro"
}
    
