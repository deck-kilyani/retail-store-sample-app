# GitHub Actions CI/CD Pipeline

This directory contains the GitHub Actions workflows for the retail store sample application's CI/CD pipeline.

## 🚀 Overview

The CI/CD pipeline provides automated:
- **Change Detection**: Identifies which microservices have been modified
- **Docker Image Building**: Builds and optimizes container images
- **ECR Integration**: Pushes images to Amazon Elastic Container Registry
- **Helm Chart Updates**: Updates chart values with new image tags
- **GitOps Integration**: Commits changes for ArgoCD synchronization

## 📁 Files Structure

```
.github/
├── workflows/
│   ├── ci-cd.yml           # Main CI/CD pipeline
│   └── validate.yml        # Workflow validation and testing
├── scripts/
│   └── validate-workflow.sh # Validation script
├── ecr-lifecycle-policy.json # ECR image cleanup policy
├── SECURITY.md             # Security configuration guide
└── README.md               # This file
```

## ⚙️ Setup Instructions

### 1. Configure GitHub Secrets

Add these secrets in your repository settings (`Settings > Secrets and variables > Actions`):

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `AWS_ACCESS_KEY_ID` | AWS Access Key | `AKIA...` |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Key | `wJalrXUt...` |
| `AWS_REGION` | AWS Region | `us-west-2` |
| `AWS_ACCOUNT_ID` | AWS Account ID | `123456789012` |

### 2. Set Up AWS IAM Permissions

Create an IAM user with the policy defined in [SECURITY.md](SECURITY.md).

### 3. Validate Configuration

Run the validation workflow:
```bash
# Trigger validation workflow
gh workflow run validate.yml
```

Or run locally:
```bash
.github/scripts/validate-workflow.sh
```

## 🔄 Workflow Triggers

### Automatic Triggers

1. **Push to gitops branch** with changes in service directories:
   ```
   src/ui/**
   src/catalog/**
   src/cart/**
   src/checkout/**
   src/orders/**
   ```

2. **Pull requests** to gitops branch (build-only, no deployment)

### Manual Trigger

Use GitHub Actions UI or CLI:

```bash
# Build all services
gh workflow run ci-cd.yml

# Build specific services
gh workflow run ci-cd.yml -f services="ui,catalog"

# Build single service
gh workflow run ci-cd.yml -f services="ui"
```

## 📊 Workflow Stages

### 1. Change Detection
- Analyzes git diff to identify modified services
- Generates build matrix for parallel execution
- Skips builds when no services are changed

### 2. Service Builds (Parallel)
- **AWS Authentication**: Validates credentials and permissions
- **ECR Repository**: Creates repositories if they don't exist
- **Docker Build**: Builds images with layer caching
- **ECR Push**: Pushes images with commit SHA tags
- **Security Scan**: Initiates vulnerability scanning

### 3. Helm Chart Updates
- Updates `values.yaml` files with new image tags
- Preserves infrastructure image configurations
- Commits changes back to the repository

### 4. Workflow Summary
- Generates comprehensive status report
- Provides troubleshooting guidance
- Shows processed services and image URIs

## 🎯 Usage Examples

### Example 1: Single Service Update

```bash
# Make changes to UI service
echo "console.log('updated');" >> src/ui/src/main/resources/static/app.js

# Commit and push
git add src/ui/
git commit -m "Update UI logging"
git push origin gitops
```

**Result**: Only the UI service will be built and deployed.

### Example 2: Multiple Service Update

```bash
# Update multiple services
echo "# Updated" >> src/catalog/README.md
echo "# Updated" >> src/cart/README.md

# Commit and push
git add src/catalog/ src/cart/
git commit -m "Update documentation"
git push origin gitops
```

**Result**: Both catalog and cart services will be built in parallel.

### Example 3: Manual Deployment

```bash
# Deploy specific services manually
gh workflow run ci-cd.yml -f services="checkout,orders"
```

**Result**: Only checkout and orders services will be built.

### Example 4: Emergency Rebuild

```bash
# Rebuild all services (useful for base image updates)
gh workflow run ci-cd.yml -f services="all"
```

**Result**: All services will be rebuilt and deployed.

## 📈 Monitoring and Observability

### GitHub Actions UI
- View workflow runs: `Actions` tab in GitHub
- Monitor build status and logs
- Download artifacts and reports

### Workflow Outputs
Each workflow run provides:
- **Services Built**: List of processed services
- **Image URIs**: ECR image locations
- **Deployment Status**: Helm chart update results

### ArgoCD Integration
After successful workflow completion:
1. ArgoCD detects Helm chart changes
2. Applications are automatically synced
3. Monitor deployment in ArgoCD UI

## 🔧 Troubleshooting

### Common Issues

#### 1. Authentication Failures
```
Error: Unable to locate credentials
```
**Solution**: Verify GitHub secrets are configured correctly.

#### 2. ECR Permission Errors
```
Error: User is not authorized to perform: ecr:CreateRepository
```
**Solution**: Check IAM permissions in [SECURITY.md](SECURITY.md).

#### 3. Docker Build Failures
```
Error: failed to solve: process "/bin/sh -c ..." did not complete successfully
```
**Solution**: Check Dockerfile syntax and dependencies.

#### 4. Git Push Conflicts
```
Error: failed to push some refs
```
**Solution**: The workflow includes automatic retry with rebase.

### Debug Mode

Enable debug logging by setting repository variable:
- Name: `ACTIONS_STEP_DEBUG`
- Value: `true`

### Validation

Run validation before making changes:
```bash
# Validate workflow configuration
.github/scripts/validate-workflow.sh

# Test specific scenarios
gh workflow run validate.yml
```

## 🔒 Security Considerations

- **Secrets Management**: All credentials stored in GitHub secrets
- **Image Scanning**: Automatic vulnerability scanning enabled
- **Minimal Permissions**: IAM policy follows least privilege principle
- **Audit Trail**: All actions logged in GitHub Actions and AWS CloudTrail

See [SECURITY.md](SECURITY.md) for detailed security configuration.

## 🚀 Performance Optimizations

### Caching Strategy
- **Docker Layers**: Cached between builds for faster execution
- **Dependencies**: Maven, Go, and Node.js dependencies cached
- **Build Context**: Optimized for minimal transfer

### Parallel Execution
- **Service Builds**: Up to 3 services built simultaneously
- **Matrix Strategy**: Independent service builds with failure isolation
- **Resource Optimization**: Appropriate runner sizes for different tasks

### Build Optimization
- **Multi-stage Builds**: Leverages existing Dockerfile optimizations
- **Layer Caching**: Reuses unchanged layers
- **Conditional Execution**: Skips unnecessary steps

## 📋 Maintenance

### Regular Tasks
1. **Rotate AWS Keys**: Update secrets monthly
2. **Review ECR Images**: Monitor repository sizes
3. **Update Dependencies**: Keep actions up to date
4. **Security Scans**: Review vulnerability reports

### Lifecycle Management
- **ECR Cleanup**: Automatic via lifecycle policies
- **Workflow Logs**: Retained per GitHub settings
- **Cache Management**: Automatic cleanup after builds

## 🤝 Contributing

### Making Changes
1. Create feature branch from `gitops`
2. Update workflow files
3. Run validation: `.github/scripts/validate-workflow.sh`
4. Test with validation workflow
5. Create pull request

### Testing Workflows
- Use validation workflow for syntax checking
- Test change detection with sample commits
- Verify matrix generation logic

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS ECR Documentation](https://docs.aws.amazon.com/ecr/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

---

For questions or issues, please check the troubleshooting section or create an issue in the repository.