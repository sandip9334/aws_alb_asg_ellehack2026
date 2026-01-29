
# AWS Application Load Balancer + Auto Scaling Group (2 instances)

This repo creates an **Application Load Balancer (ALB)** in front of an **Auto Scaling Group** with **2 Amazon Linux 2 web servers**, deployed across **two default subnets** in your **default VPC**. Each instance serves a fancy HTML page with live instance metadata (IMDSv2).

## What gets created
- Internet‑facing **ALB** listening on **HTTP :80**
- **Target Group** with HTTP health checks (`/`, matcher `200-399`)
- **Auto Scaling Group** (min=2, desired=2) across two default subnets
- **Launch Template** using Amazon Linux 2 and **user data** that installs Apache and writes the page
- **Security Groups**: ALB open to the internet; instances only allow HTTP from the ALB SG

## Prerequisites
- Terraform **>= 1.5**
- AWS credentials configured (e.g., `aws configure`)
- A **default VPC** with at least **two default subnets** in your chosen region

## Quick start
```bash
terraform init
terraform apply -auto-approve
```

After a minute or two, open the **ALB DNS name** output in your browser.

### Customize
- Region & size: edit `terraform.tfvars` (or pass `-var` flags)
- Key pair for SSH: add `key_name = "your-keypair"` to the `aws_launch_template`
- HTTPS: add an ACM cert + 443 listener, and redirect 80→443 if you like

## Cleanup
```bash
terraform destroy -auto-approve
```

## Repo layout
```
.
├─ main.tf
├─ variables.tf
├─ outputs.tf
├─ user_data.sh
├─ terraform.tfvars.sample
├─ .gitignore
└─ README.md
```
