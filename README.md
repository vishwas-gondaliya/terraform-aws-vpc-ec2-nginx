# terraform-aws-vpc-ec2-nginx

Minimal Terraform project that provisions an **AWS VPC (2 public subnets)** and launches an **EC2 (Amazon Linux 2023)** with **Nginx** installed via `user_data`. After `apply`, Terraform prints the instance **public IP/DNS** so you can open the Nginx page.

## What this creates
- **VPC** `10.0.0.0/16` with DNS support/hostnames
- **2 public subnets** across 2 AZs (auto-assign public IPs)
- **Internet Gateway** + public route table (`0.0.0.0/0 → IGW`)
- **Security Group**: inbound **HTTP 80** from anywhere; all egress
- **EC2** (Amazon Linux 2023, micro type) in a public subnet
- **user_data** installs & starts **Nginx** and writes a default page
- **Outputs**: EC2 public IP/DNS + core IDs (VPC, subnets, route table)

## Files
```
providers.tf   # provider + versions, profile/region
main.tf        # VPC, subnets, IGW, routes, SG, EC2, user_data
variables.tf   # aws_region, project, vpc_cidr, instance_type
outputs.tf     # public IP/DNS + IDs
.gitignore     # ignores .terraform/ and *.tfstate
```

## Quick start
```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
# Open: http://<ec2_public_ip output>
```

## Variables
| Name            | Type   | Default         | Notes                                        |
|-----------------|--------|-----------------|----------------------------------------------|
| `aws_region`    | string | `us-east-1`     | Deployment region                            |
| `project`       | string | `vpc-ec2-nginx` | Tag/name prefix                              |
| `vpc_cidr`      | string | `10.0.0.0/16`   | VPC CIDR                                     |
| `instance_type` | string | `t2.micro`      | Use `t3.micro` if `t2` not available         |

Optional `terraform.tfvars`:
```hcl
aws_region    = "ca-central-1"
instance_type = "t3.micro"
```

## Outputs
- `ec2_public_ip`
- `ec2_public_dns`
- `vpc_id`
- `public_subnet_ids`
- `public_route_table_id`


## Destroy
```bash
terraform destroy
```
