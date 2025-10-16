# AWS Project Complete Cleanup Script
# WARNING: This will delete ALL resources and is irreversible!

param(
    [Parameter(Mandatory=$false)]
    [string]$ClusterName = "",
    [Parameter(Mandatory=$false)]
    [string]$Region = "us-west-2",
    [Parameter(Mandatory=$false)]
    [switch]$Force = $false
)

Write-Host "=== AWS PROJECT CLEANUP SCRIPT ===" -ForegroundColor Red
Write-Host "This will PERMANENTLY DELETE all AWS resources!" -ForegroundColor Red
Write-Host ""

# Get cluster name if not provided
if (-not $ClusterName) {
    Write-Host "Getting EKS cluster name..." -ForegroundColor Yellow
    $clusters = eksctl get clusters -o json | ConvertFrom-Json
    if ($clusters.Count -gt 0) {
        $ClusterName = $clusters[0].Name
        Write-Host "Found cluster: $ClusterName" -ForegroundColor Green
    } else {
        Write-Host "No EKS clusters found. Continuing with other cleanup..." -ForegroundColor Yellow
    }
}

if (-not $Force) {
    Write-Host "Cluster to delete: $ClusterName" -ForegroundColor Yellow
    Write-Host "Region: $Region" -ForegroundColor Yellow
    Write-Host ""
    $confirm = Read-Host "Are you sure you want to delete ALL resources? Type 'DELETE' to confirm"
    if ($confirm -ne "DELETE") {
        Write-Host "Cleanup cancelled." -ForegroundColor Green
        exit
    }
}

Write-Host ""
Write-Host "Starting cleanup process..." -ForegroundColor Red

try {
    # Step 1: Delete ArgoCD applications
    Write-Host "[1/8] Deleting ArgoCD applications..." -ForegroundColor Cyan
    kubectl delete applications --all -n argocd --ignore-not-found=true --timeout=60s
    Start-Sleep -Seconds 5

    # Step 2: Delete Kubernetes namespaces
    Write-Host "[2/8] Deleting Kubernetes namespaces..." -ForegroundColor Cyan
    $namespaces = @("retail-store", "ingress-nginx", "cert-manager", "argocd")
    foreach ($ns in $namespaces) {
        Write-Host "  Deleting namespace: $ns" -ForegroundColor White
        kubectl delete namespace $ns --force --grace-period=0 --ignore-not-found=true --timeout=120s
    }
    Start-Sleep -Seconds 10

    # Step 3: Delete EKS cluster
    if ($ClusterName) {
        Write-Host "[3/8] Deleting EKS cluster: $ClusterName (this takes 10-15 minutes)..." -ForegroundColor Cyan
        eksctl delete cluster --name $ClusterName --region $Region --wait
        Write-Host "  EKS cluster deleted successfully!" -ForegroundColor Green
    } else {
        Write-Host "[3/8] No EKS cluster to delete." -ForegroundColor Yellow
    }

    # Step 4: Delete ECR repositories
    Write-Host "[4/8] Deleting ECR repositories..." -ForegroundColor Cyan
    $repos = aws ecr describe-repositories --region $Region --query 'repositories[].repositoryName' --output text 2>$null
    if ($repos -and $repos -ne "") {
        $repoList = $repos -split "`t"
        foreach ($repo in $repoList) {
            if ($repo.Trim() -ne "") {
                Write-Host "  Deleting ECR repository: $repo" -ForegroundColor White
                aws ecr delete-repository --repository-name $repo.Trim() --force --region $Region 2>$null
            }
        }
        Write-Host "  ECR repositories deleted!" -ForegroundColor Green
    } else {
        Write-Host "  No ECR repositories found." -ForegroundColor Yellow
    }

    # Step 5: Clean up Load Balancers
    Write-Host "[5/8] Cleaning up Load Balancers..." -ForegroundColor Cyan
    $lbs = aws elbv2 describe-load-balancers --region $Region --query 'LoadBalancers[].LoadBalancerArn' --output text 2>$null
    if ($lbs -and $lbs -ne "") {
        $lbList = $lbs -split "`t"
        foreach ($lb in $lbList) {
            if ($lb.Trim() -ne "") {
                Write-Host "  Deleting Load Balancer: $lb" -ForegroundColor White
                aws elbv2 delete-load-balancer --load-balancer-arn $lb.Trim() --region $Region 2>$null
            }
        }
    }

    # Step 6: Clean up unattached EBS volumes
    Write-Host "[6/8] Cleaning up unattached EBS volumes..." -ForegroundColor Cyan
    $volumes = aws ec2 describe-volumes --filters "Name=status,Values=available" --query 'Volumes[].VolumeId' --output text --region $Region 2>$null
    if ($volumes -and $volumes -ne "") {
        $volumeList = $volumes -split "`t"
        foreach ($volume in $volumeList) {
            if ($volume.Trim() -ne "") {
                Write-Host "  Deleting EBS volume: $volume" -ForegroundColor White
                aws ec2 delete-volume --volume-id $volume.Trim() --region $Region 2>$null
            }
        }
        Write-Host "  EBS volumes cleaned up!" -ForegroundColor Green
    } else {
        Write-Host "  No unattached EBS volumes found." -ForegroundColor Yellow
    }

    # Step 7: Release unassociated Elastic IPs
    Write-Host "[7/8] Releasing unassociated Elastic IPs..." -ForegroundColor Cyan
    $eips = aws ec2 describe-addresses --query 'Addresses[?AssociationId==null].AllocationId' --output text --region $Region 2>$null
    if ($eips -and $eips -ne "") {
        $eipList = $eips -split "`t"
        foreach ($eip in $eipList) {
            if ($eip.Trim() -ne "") {
                Write-Host "  Releasing Elastic IP: $eip" -ForegroundColor White
                aws ec2 release-address --allocation-id $eip.Trim() --region $Region 2>$null
            }
        }
        Write-Host "  Elastic IPs released!" -ForegroundColor Green
    } else {
        Write-Host "  No unassociated Elastic IPs found." -ForegroundColor Yellow
    }

    # Step 8: Clean up CloudFormation stacks
    Write-Host "[8/8] Cleaning up CloudFormation stacks..." -ForegroundColor Cyan
    if ($ClusterName) {
        $stacks = aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE --query "StackSummaries[?contains(StackName, 'eksctl-$ClusterName')].StackName" --output text --region $Region 2>$null
        if ($stacks -and $stacks -ne "") {
            $stackList = $stacks -split "`t"
            foreach ($stack in $stackList) {
                if ($stack.Trim() -ne "") {
                    Write-Host "  Deleting CloudFormation stack: $stack" -ForegroundColor White
                    aws cloudformation delete-stack --stack-name $stack.Trim() --region $Region 2>$null
                }
            }
        }
    }

    Write-Host ""
    Write-Host "🎉 CLEANUP COMPLETED SUCCESSFULLY!" -ForegroundColor Green
    Write-Host ""
    Write-Host "✅ All AWS resources have been deleted" -ForegroundColor Green
    Write-Host "✅ No more hourly charges for EKS, EC2, Load Balancers" -ForegroundColor Green
    Write-Host "✅ ECR repositories and container images deleted" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 MANUAL STEPS REMAINING:" -ForegroundColor Yellow
    Write-Host "1. Remove DNS CNAME record for tastydrive.store from spaceship.com" -ForegroundColor White
    Write-Host "2. Verify in AWS Console that all resources are deleted" -ForegroundColor White
    Write-Host "3. Check AWS Billing Dashboard in 24-48 hours to confirm charges stopped" -ForegroundColor White
    Write-Host ""
    Write-Host "💰 Expected cost savings: ~$50-100/month" -ForegroundColor Green

} catch {
    Write-Host ""
    Write-Host "❌ Error during cleanup: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please check the aws-cleanup-guide.md for manual cleanup steps." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Cleanup script finished." -ForegroundColor Cyan