# Security Configuration for CI/CD Pipeline

## Required GitHub Secrets

Configure these secrets in your GitHub repository settings (`Settings > Secrets and variables > Actions`):

| Secret Name | Description | Example Value | Required |
|-------------|-------------|---------------|----------|
| `AWS_ACCESS_KEY_ID` | AWS Access Key for ECR/EKS access | `AKIA...` | ✅ |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Access Key | `wJalrXUt...` | ✅ |
| `AWS_REGION` | AWS Region for ECR repositories | `us-west-2` | ✅ |
| `AWS_ACCOUNT_ID` | AWS Account ID for ECR URLs | `123456789012` | ✅ |

## Required AWS IAM Permissions

Create an IAM user with the following minimal permissions policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ECRRepositoryManagement",
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:CreateRepository",
        "ecr:DescribeRepositories",
        "ecr:PutLifecyclePolicy"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ECRImageManagement",
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:PutImage",
        "ecr:DescribeImages"
      ],
      "Resource": "arn:aws:ecr:*:*:repository/retail-store-*"
    },
    {
      "Sid": "STSGetCallerIdentity",
      "Effect": "Allow",
      "Action": [
        "sts:GetCallerIdentity"
      ],
      "Resource": "*"
    }
  ]
}
```

## Security Best Practices

### 1. Credential Management
- ✅ Use GitHub repository secrets for AWS credentials
- ✅ Enable ECR password masking in workflow logs
- ✅ Validate credentials early in the workflow
- ✅ Use minimal required IAM permissions
- 🔄 Consider implementing OIDC for temporary credentials (future enhancement)

### 2. Container Security
- ✅ Enable ECR vulnerability scanning on push
- ✅ Use AES256 encryption for ECR repositories
- ✅ Implement lifecycle policies for image cleanup
- ✅ Use official base images (Amazon Linux 2023)

### 3. Git Security
- ✅ Use GitHub Actions bot token for commits
- ✅ Add `[skip ci]` to prevent infinite loops
- ✅ Validate YAML syntax before committing
- ✅ Use rebase strategy to avoid merge conflicts

### 4. Workflow Security
- ✅ Use specific action versions (not @main)
- ✅ Implement retry mechanisms for transient failures
- ✅ Fail fast on authentication errors
- ✅ Mask sensitive information in logs

## Security Monitoring

### ECR Security Features
- **Vulnerability Scanning**: Enabled on all repositories
- **Encryption**: AES256 encryption at rest
- **Access Logging**: CloudTrail integration (configure separately)
- **Image Signing**: Planned for future implementation

### Workflow Security
- **Secret Exposure**: Secrets are masked in workflow logs
- **Permission Boundaries**: Minimal IAM permissions
- **Audit Trail**: All actions logged in GitHub Actions
- **Branch Protection**: Recommended for production branches

## Incident Response

### Compromised Credentials
1. Immediately rotate AWS access keys
2. Update GitHub repository secrets
3. Review CloudTrail logs for unauthorized access
4. Scan ECR repositories for unauthorized images

### Security Vulnerabilities
1. Review ECR vulnerability scan results
2. Update base images and dependencies
3. Rebuild and redeploy affected services
4. Monitor for exploitation attempts

## Compliance Considerations

### Data Protection
- No sensitive data in container images
- Secrets managed through GitHub/AWS secret stores
- Audit logs retained for compliance requirements

### Access Control
- Principle of least privilege for IAM permissions
- Role-based access for GitHub repository
- Multi-factor authentication recommended

## Future Security Enhancements

### Planned Improvements
1. **OIDC Integration**: Replace long-lived AWS keys with temporary tokens
2. **Image Signing**: Implement cosign for container image signing
3. **Policy as Code**: Add OPA policies for deployment validation
4. **SBOM Generation**: Software Bill of Materials for supply chain security
5. **Runtime Security**: Integration with container runtime security tools

### Monitoring Enhancements
1. **Security Dashboards**: Centralized security monitoring
2. **Automated Alerts**: Real-time security incident notifications
3. **Compliance Reporting**: Automated compliance status reports