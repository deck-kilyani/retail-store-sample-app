#!/bin/bash

# Workflow Validation Script
# This script validates the CI/CD workflow configuration and dependencies

set -euo pipefail

echo "🔍 Validating CI/CD Workflow Configuration"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Validation functions
validate_file() {
    local file="$1"
    local description="$2"
    
    if [[ -f "$file" ]]; then
        echo -e "${GREEN}✅${NC} $description: $file"
        return 0
    else
        echo -e "${RED}❌${NC} $description: $file (missing)"
        return 1
    fi
}

validate_yaml() {
    local file="$1"
    local description="$2"
    
    if validate_file "$file" "$description"; then
        if command -v yq >/dev/null 2>&1; then
            if yq eval '.' "$file" >/dev/null 2>&1; then
                echo -e "${GREEN}✅${NC} YAML syntax valid: $file"
                return 0
            else
                echo -e "${RED}❌${NC} YAML syntax invalid: $file"
                return 1
            fi
        else
            echo -e "${YELLOW}⚠️${NC} yq not available, skipping YAML validation for $file"
            return 0
        fi
    else
        return 1
    fi
}

validate_service_structure() {
    local service="$1"
    local errors=0
    
    echo "Validating service: $service"
    
    # Check service directory
    if [[ ! -d "src/$service" ]]; then
        echo -e "${RED}❌${NC} Service directory missing: src/$service"
        ((errors++))
    fi
    
    # Check Dockerfile
    if [[ ! -f "src/$service/Dockerfile" ]]; then
        echo -e "${RED}❌${NC} Dockerfile missing: src/$service/Dockerfile"
        ((errors++))
    fi
    
    # Check Helm chart
    if [[ ! -d "src/$service/chart" ]]; then
        echo -e "${RED}❌${NC} Helm chart directory missing: src/$service/chart"
        ((errors++))
    fi
    
    # Check values.yaml
    if [[ ! -f "src/$service/chart/values.yaml" ]]; then
        echo -e "${RED}❌${NC} Helm values.yaml missing: src/$service/chart/values.yaml"
        ((errors++))
    else
        # Validate values.yaml structure
        if command -v yq >/dev/null 2>&1; then
            if ! yq eval '.image.repository' "src/$service/chart/values.yaml" >/dev/null 2>&1; then
                echo -e "${RED}❌${NC} Missing image.repository in values.yaml: src/$service/chart/values.yaml"
                ((errors++))
            fi
            
            if ! yq eval '.image.tag' "src/$service/chart/values.yaml" >/dev/null 2>&1; then
                echo -e "${RED}❌${NC} Missing image.tag in values.yaml: src/$service/chart/values.yaml"
                ((errors++))
            fi
        fi
    fi
    
    if [[ $errors -eq 0 ]]; then
        echo -e "${GREEN}✅${NC} Service structure valid: $service"
    else
        echo -e "${RED}❌${NC} Service structure invalid: $service ($errors errors)"
    fi
    
    return $errors
}

# Main validation
echo "1. Validating workflow files..."
total_errors=0

# Validate main workflow file
if ! validate_yaml ".github/workflows/ci-cd.yml" "Main CI/CD workflow"; then
    ((total_errors++))
fi

# Validate ECR lifecycle policy
if ! validate_yaml ".github/ecr-lifecycle-policy.json" "ECR lifecycle policy"; then
    ((total_errors++))
fi

# Validate security documentation
if ! validate_file ".github/SECURITY.md" "Security documentation"; then
    ((total_errors++))
fi

echo ""
echo "2. Validating service structures..."

# Validate each service
services=("ui" "catalog" "cart" "checkout" "orders")
for service in "${services[@]}"; do
    if ! validate_service_structure "$service"; then
        ((total_errors++))
    fi
done

echo ""
echo "3. Validating workflow syntax..."

# Check for common workflow issues
workflow_file=".github/workflows/ci-cd.yml"
if [[ -f "$workflow_file" ]]; then
    # Check for required secrets
    required_secrets=("AWS_ACCESS_KEY_ID" "AWS_SECRET_ACCESS_KEY" "AWS_REGION" "AWS_ACCOUNT_ID")
    for secret in "${required_secrets[@]}"; do
        if grep -q "secrets\.$secret" "$workflow_file"; then
            echo -e "${GREEN}✅${NC} Secret reference found: $secret"
        else
            echo -e "${RED}❌${NC} Secret reference missing: $secret"
            ((total_errors++))
        fi
    done
    
    # Check for required actions
    required_actions=("actions/checkout" "aws-actions/configure-aws-credentials" "aws-actions/amazon-ecr-login")
    for action in "${required_actions[@]}"; do
        if grep -q "uses: $action" "$workflow_file"; then
            echo -e "${GREEN}✅${NC} Action found: $action"
        else
            echo -e "${RED}❌${NC} Action missing: $action"
            ((total_errors++))
        fi
    done
fi

echo ""
echo "4. Validating dependencies..."

# Check if required tools are available (for local testing)
tools=("docker" "git" "jq")
for tool in "${tools[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        echo -e "${GREEN}✅${NC} Tool available: $tool"
    else
        echo -e "${YELLOW}⚠️${NC} Tool not available (OK for CI): $tool"
    fi
done

echo ""
echo "=========================================="
if [[ $total_errors -eq 0 ]]; then
    echo -e "${GREEN}🎉 All validations passed!${NC}"
    echo "The CI/CD workflow is ready for use."
    exit 0
else
    echo -e "${RED}❌ Validation failed with $total_errors errors${NC}"
    echo "Please fix the issues above before using the workflow."
    exit 1
fi