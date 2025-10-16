# Complete AWS Project Cleanup Guide

## Overview
This guide will help you completely delete and destroy all AWS resources created for the retail store project to avoid ongoing charges.

## ⚠️ WARNING
**This will permanently delete all resources and data. Make sure you have backups of any important data before proceeding.**

## Cleanup Order (Important!)
Follow this order to avoid dependency issues:

### 1. Delete Kubernetes Applications (ArgoCD)
First, delete all applications through ArgoCD to clean up Kubernetes resources:

```bash
# Delete all ArgoCD applications
kubectl delete application retail-store-ui -n argocd
kubectl delete application retail-store-cart -n argocd
kubectl delete application retail-store-catalog -n argocd
kubectl delete application retail-store-checkout -n argocd
kubectl delete application retail-store-orders -n argocd

# Or delete all at once
kubectl delete applications --all -n argocd
```

### 2. Delete Kubernetes Resources Manually (if ArgoCD cleanup incomplete)
```bash
# Delete all resources in retail-store namespace
kubectl delete namespace retail-store --force --grace-period=0

# Delete ingress controller and related resources
kubectl delete namespace ingress-nginx --force --grace-period=0

# Delete cert-manager
kubectl delete namespace cert-manager --force --grace-period=0

# Delete ArgoCD
kubectl delete namespace argocd --force --grace-period=0

# Delete any remaining namespaces
kubectl get namespaces
kubectl delete namespace [any-remaining-app-namespaces] --force --grace-period=0
```

### 3. Delete EKS Cluster
```bash
# Get cluster name
eksctl get clusters

# Delete the EKS cluster (this will take 10-15 minutes)
eksctl delete cluster --name [your-cluster-name] --region us-west-2

# Alternative using AWS CLI
aws eks delete-cluster --name [your-cluster-name] --region us-west-2
```

### 4. Clean Up Load Balancers (if not auto-deleted)
```bash
# List load balancers
aws elbv2 describe-load-balancers --region us-west-2

# Delete specific load balancers if they still exist
aws elbv2 delete-load-balancer --load-balancer-arn [load-balancer-arn] --region us-west-2

# List classic load balancers
aws elb describe-load-balancers --region us-west-2

# Delete classic load balancers if any
aws elb delete-load-balancer --load-balancer-name [load-balancer-name] --region us-west-2
```

### 5. Delete ECR Repositories
```bash
# List ECR repositories
aws ecr describe-repositories --region us-west-2

# Delete ECR repositories (this will delete all container images)
aws ecr delete-repository --repository-name retail-store-ui --force --region us-west-2
aws ecr delete-repository --repository-name retail-store-cart --force --region us-west-2
aws ecr delete-repository --repository-name retail-store-catalog --force --region us-west-2
aws ecr delete-repository --repository-name retail-store-checkout --force --region us-west-2
aws ecr delete-repository --repository-name retail-store-orders --force --region us-west-2

# Or delete all ECR repositories at once
aws ecr describe-repositories --region us-west-2 --query 'repositories[].repositoryName' --output text | xargs -I {} aws ecr delete-repository --repository-name {} --force --region us-west-2
```

### 6. Delete VPC and Networking Resources
```bash
# List VPCs (look for the EKS VPC)
aws ec2 describe-vpcs --region us-west-2

# Get VPC ID for your EKS cluster
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=eksctl-*" --query 'Vpcs[0].VpcId' --output text --region us-west-2)

# Delete NAT Gateways first
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" --region us-west-2
aws ec2 delete-nat-gateway --nat-gateway-id [nat-gateway-id] --region us-west-2

# Delete Internet Gateways
aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --region us-west-2
aws ec2 detach-internet-gateway --internet-gateway-id [igw-id] --vpc-id $VPC_ID --region us-west-2
aws ec2 delete-internet-gateway --internet-gateway-id [igw-id] --region us-west-2

# Delete Subnets
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --region us-west-2
aws ec2 delete-subnet --subnet-id [subnet-id] --region us-west-2

# Delete Route Tables
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --region us-west-2
aws ec2 delete-route-table --route-table-id [route-table-id] --region us-west-2

# Delete Security Groups (except default)
aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" --region us-west-2
aws ec2 delete-security-group --group-id [security-group-id] --region us-west-2

# Finally delete VPC
aws ec2 delete-vpc --vpc-id $VPC_ID --region us-west-2
```

### 7. Delete IAM Roles and Policies
```bash
# List IAM roles related to EKS
aws iam list-roles --query 'Roles[?contains(RoleName, `eksctl`) || contains(RoleName, `EKS`) || contains(RoleName, `NodeInstance`)].RoleName' --output text

# Delete EKS service roles
aws iam detach-role-policy --role-name [role-name] --policy-arn [policy-arn]
aws iam delete-role --role-name [role-name]

# Common EKS roles to delete:
# - eksctl-[cluster-name]-cluster-ServiceRole-*
# - eksctl-[cluster-name]-nodegroup-*-NodeInstanceRole-*
# - AWSServiceRoleForAmazonEKS*
```

### 8. Delete CloudFormation Stacks (if using eksctl)
```bash
# List CloudFormation stacks
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE --region us-west-2

# Delete eksctl-created stacks
aws cloudformation delete-stack --stack-name eksctl-[cluster-name]-cluster --region us-west-2
aws cloudformation delete-stack --stack-name eksctl-[cluster-name]-nodegroup-[nodegroup-name] --region us-west-2
```

### 9. Clean Up EBS Volumes
```bash
# List unattached EBS volumes
aws ec2 describe-volumes --filters "Name=status,Values=available" --region us-west-2

# Delete unattached volumes
aws ec2 delete-volume --volume-id [volume-id] --region us-west-2
```

### 10. Clean Up Elastic IPs
```bash
# List unassociated Elastic IPs
aws ec2 describe-addresses --query 'Addresses[?AssociationId==null]' --region us-west-2

# Release Elastic IPs
aws ec2 release-address --allocation-id [allocation-id] --region us-west-2
```

## Automated Cleanup Script

Here's a PowerShell script to automate most of the cleanup:

```powershell
# Set your cluster name and region
$CLUSTER_NAME = "your-cluster-name"
$REGION = "us-west-2"

Write-Host "Starting AWS cleanup for cluster: $CLUSTER_NAME" -ForegroundColor Yellow

# 1. Delete ArgoCD applications
Write-Host "Deleting ArgoCD applications..." -ForegroundColor Cyan
kubectl delete applications --all -n argocd --ignore-not-found=true

# 2. Delete namespaces
Write-Host "Deleting Kubernetes namespaces..." -ForegroundColor Cyan
kubectl delete namespace retail-store --force --grace-period=0 --ignore-not-found=true
kubectl delete namespace ingress-nginx --force --grace-period=0 --ignore-not-found=true
kubectl delete namespace cert-manager --force --grace-period=0 --ignore-not-found=true
kubectl delete namespace argocd --force --grace-period=0 --ignore-not-found=true

# 3. Delete EKS cluster
Write-Host "Deleting EKS cluster (this will take 10-15 minutes)..." -ForegroundColor Cyan
eksctl delete cluster --name $CLUSTER_NAME --region $REGION

# 4. Delete ECR repositories
Write-Host "Deleting ECR repositories..." -ForegroundColor Cyan
$repos = aws ecr describe-repositories --region $REGION --query 'repositories[].repositoryName' --output text
if ($repos) {
    $repos.Split("`t") | ForEach-Object {
        aws ecr delete-repository --repository-name $_ --force --region $REGION
    }
}

# 5. Clean up unattached EBS volumes
Write-Host "Cleaning up unattached EBS volumes..." -ForegroundColor Cyan
$volumes = aws ec2 describe-volumes --filters "Name=status,Values=available" --query 'Volumes[].VolumeId' --output text --region $REGION
if ($volumes) {
    $volumes.Split("`t") | ForEach-Object {
        aws ec2 delete-volume --volume-id $_ --region $REGION
    }
}

# 6. Release unassociated Elastic IPs
Write-Host "Releasing unassociated Elastic IPs..." -ForegroundColor Cyan
$eips = aws ec2 describe-addresses --query 'Addresses[?AssociationId==null].AllocationId' --output text --region $REGION
if ($eips) {
    $eips.Split("`t") | ForEach-Object {
        aws ec2 release-address --allocation-id $_ --region $REGION
    }
}

Write-Host "Cleanup completed!" -ForegroundColor Green
Write-Host "Please check AWS Console to verify all resources are deleted." -ForegroundColor Yellow
```

## Manual Verification Steps

After running the cleanup:

1. **AWS Console Verification:**
   - Go to AWS Console → EKS → Clusters (should be empty)
   - Go to EC2 → Load Balancers (should be empty or only unrelated ones)
   - Go to ECR → Repositories (should be empty or only unrelated ones)
   - Go to VPC → Your VPCs (should not have eksctl-created VPCs)
   - Go to CloudFormation → Stacks (should not have eksctl stacks)

2. **Cost Verification:**
   - Go to AWS Billing Dashboard
   - Check that no ongoing charges for EKS, EC2, Load Balancers, etc.

## Important Notes

- **DNS Records:** Don't forget to remove the CNAME record for `tastydrive.store` from your DNS provider (spaceship.com)
- **Billing:** It may take 24-48 hours for all charges to stop appearing
- **Backups:** This process is irreversible - make sure you have backups if needed
- **Dependencies:** Some resources may fail to delete due to dependencies - run the commands multiple times if needed

## Estimated Time
- Total cleanup time: 15-30 minutes
- EKS cluster deletion: 10-15 minutes (longest part)
- Cost savings: Immediate (no more hourly EKS charges)

## Cost Impact
After cleanup, you should see these charges stop:
- EKS cluster: ~$0.10/hour
- EC2 instances (worker nodes): ~$0.05-0.20/hour per instance
- Load balancers: ~$0.025/hour
- NAT Gateway: ~$0.045/hour
- EBS volumes: ~$0.10/GB/month