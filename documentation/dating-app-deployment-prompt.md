# Dating App Backend AWS EKS Deployment Setup - AI Prompt

## Project Overview

I need help setting up AWS EKS deployment infrastructure for a Node.js dating app backend that follows microservices architecture in a monorepo structure.

### Reference Architecture

I want to follow a similar pattern to this existing project structure:

- **Terraform modules** for infrastructure as code
- **AWS EKS with Auto Mode** for Kubernetes orchestration
- **ArgoCD** for GitOps continuous deployment
- **Helm charts** for application packaging
- **ECR** for container registry
- **Multi-environment support** (dev/staging/prod)
- **Modular architecture** with reusable components

The reference project had these key components that I want to adapt:

```
project-structure/
├── terraform/
│   ├── modules/           # Reusable infrastructure modules
│   ├── environments/      # Environment-specific configs
│   └── main.tf
├── helm-charts/           # Application Helm charts
├── argocd/               # GitOps configurations
│   ├── projects/
│   ├── applications/
│   └── app-of-apps/
└── src/                  # Application source code
```

### Key Patterns to Follow

1. **Modular Terraform**: Infrastructure broken into reusable modules
2. **GitOps with ArgoCD**: Declarative deployments from Git repositories
3. **Helm for Packaging**: Templated Kubernetes manifests with values
4. **Multi-Environment**: Separate configurations for dev/staging/prod
5. **Container Registry**: ECR for storing Docker images
6. **Auto Scaling**: EKS Auto Mode for simplified node management
7. **Security First**: Private subnets, IAM roles, security groups
8. **Observability**: Monitoring, logging, and alerting built-in

## Application Architecture

### Technology Stack

- **Backend**: Node.js microservices
- **Architecture**: Microservices in monorepo
- **Inter-service Communication**: gRPC
- **API Gateway**: HTTP to gRPC conversion
- **Database**: MongoDB (primary database)
- **Caching**: Redis
- **Message Queue**: Apache Kafka
- **Container Registry**: AWS ECR
- **Orchestration**: Kubernetes (AWS EKS with Auto Mode)
- **CI/CD**: ArgoCD for GitOps
- **Package Management**: Helm Charts
- **Infrastructure**: Terraform with modules

### Microservices List (13 services)

1. **api-gateway** - HTTP to gRPC gateway, handles all external requests
2. **auth-service** - Authentication, JWT tokens, user sessions
3. **user-service** - User profiles, preferences, account management
4. **experience-service** - User experiences, reviews, ratings
5. **match-interaction-service** - Likes, dislikes, swipe interactions
6. **booking-service** - Date bookings, reservations, scheduling
7. **hungry-hub-service** - Restaurant integration, food ordering
8. **notification-service** - Push notifications, email, SMS
9. **payment-service** - Payments, subscriptions, billing
10. **match-maker-service** - Matching algorithm, compatibility scoring
11. **date-service** - Date planning, suggestions, management
12. **communication-service** - Chat, messaging, video calls
13. **ai-service** - AI recommendations, personality analysis

### Third-Party Service Integrations (Requires NAT Gateway)

- **Hungry Hub** - Restaurant and food delivery integration
- **Customer.io** - Email marketing and automation
- **Pusher** - Real-time messaging and notifications
- **Twilio** - SMS, voice calls, video calls
- **Stripe** - Payment processing
- **RevenueCat** - Subscription management
- **Stream** - Chat and activity feeds

### Database & Infrastructure Requirements

- **MongoDB**: Primary database for all services
- **Redis**: Caching layer and session storage
- **Kafka**: Message queue for async communication
- **NAT Gateway**: Required for third-party API calls
- **Load Balancers**: For high availability
- **Auto Scaling**: Based on demand

## Infrastructure Requirements

### AWS EKS Setup

- **EKS Auto Mode**: Simplified node management
- **Multi-AZ deployment**: High availability
- **Private subnets**: For security
- **Public subnets**: For load balancers
- **NAT Gateway**: For outbound internet access to third-party APIs

### Terraform Structure Needed

Based on infrastructure-as-code best practices, create this modular structure:

```
terraform/
├── modules/                    # Reusable infrastructure components
│   ├── eks/                   # EKS cluster module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── networking/            # VPC, subnets, NAT gateway
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── databases/             # RDS, DocumentDB options
│   ├── monitoring/            # CloudWatch, Prometheus setup
│   └── security/              # IAM roles, security groups
├── environments/              # Environment-specific configurations
│   ├── dev/
│   │   ├── main.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   ├── staging/
│   └── prod/
├── main.tf                    # Root configuration
└── versions.tf                # Provider versions
```

### Helm Charts Structure Needed

Each microservice should have its own Helm chart following this pattern:

```
helm-charts/
├── api-gateway/               # HTTP to gRPC gateway
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── templates/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── ingress.yaml
│   │   └── configmap.yaml
├── auth-service/              # Authentication service
├── user-service/              # User management
├── experience-service/        # User experiences
├── match-interaction-service/ # Swipe interactions
├── booking-service/           # Date bookings
├── hungry-hub-service/        # Restaurant integration
├── notification-service/      # Push notifications
├── payment-service/           # Payment processing
├── match-maker-service/       # Matching algorithm
├── date-service/              # Date management
├── communication-service/     # Chat and messaging
├── ai-service/                # AI recommendations
├── infrastructure/            # Infrastructure components
│   ├── mongodb/               # Database
│   ├── redis/                 # Caching
│   └── kafka/                 # Message queue
└── shared/                    # Shared templates and helpers
    └── templates/
```

### ArgoCD Applications Structure

Implement GitOps pattern with ArgoCD managing all deployments:

```
argocd/
├── projects/                           # ArgoCD project definitions
│   └── dating-app-project.yaml        # Main project with repositories and permissions
├── applications/                       # Individual application definitions
│   ├── infrastructure/                 # Infrastructure components first
│   │   ├── mongodb.yaml               # Database deployment
│   │   ├── redis.yaml                 # Cache deployment
│   │   ├── kafka.yaml                 # Message queue deployment
│   │   └── ingress-nginx.yaml         # Ingress controller
│   └── services/                       # Microservices applications
│       ├── api-gateway.yaml           # External facing gateway
│       ├── auth-service.yaml          # Authentication service
│       ├── user-service.yaml          # User management
│       ├── match-maker-service.yaml   # Core matching logic
│       ├── payment-service.yaml       # Payment processing
│       ├── notification-service.yaml  # Notifications
│       └── [remaining services...]    # Other microservices
└── app-of-apps/                       # App of Apps pattern
    ├── infrastructure.yaml            # Deploy infrastructure first
    ├── core-services.yaml             # Deploy core services second
    └── business-services.yaml         # Deploy business logic last
```

## Specific Requirements

### Security & Networking

1. **Private EKS cluster** with private endpoints
2. **NAT Gateway** in each AZ for third-party API access
3. **Security Groups** with least privilege access
4. **Network policies** for service-to-service communication
5. **Secrets management** for API keys and credentials
6. **TLS termination** at load balancer level

### Service Communication

1. **gRPC** for internal service communication
2. **Service mesh** consideration (Istio optional)
3. **Service discovery** via Kubernetes DNS
4. **Load balancing** for gRPC services
5. **Circuit breakers** and retry policies

### Data Layer

1. **MongoDB cluster** (Atlas or self-hosted)
2. **Redis cluster** for caching and sessions
3. **Kafka cluster** for event streaming
4. **Persistent volumes** for stateful services
5. **Backup strategies** for data protection

### Monitoring & Observability

1. **Prometheus** for metrics collection
2. **Grafana** for visualization
3. **Jaeger** for distributed tracing
4. **ELK Stack** for centralized logging
5. **Health checks** for all services

### CI/CD Pipeline

1. **GitHub Actions** or **GitLab CI** for building images
2. **ECR** for container registry
3. **ArgoCD** for GitOps deployment
4. **Helm** for package management
5. **Multi-environment** support (dev/staging/prod)

## Expected Deliverables

### Phase 1: Infrastructure Setup

1. Terraform modules for AWS infrastructure
2. EKS cluster with Auto Mode
3. VPC with public/private subnets
4. NAT Gateway setup
5. Security groups and IAM roles

### Phase 2: Database & Message Queue

1. MongoDB deployment (Helm chart)
2. Redis cluster setup
3. Kafka cluster deployment
4. Persistent storage configuration

### Phase 3: Core Services

1. API Gateway deployment
2. Auth service with JWT handling
3. User service with MongoDB integration
4. Basic service-to-service gRPC communication

### Phase 4: Business Logic Services

1. Match-making service
2. Booking service
3. Payment service integration
4. Notification service

### Phase 5: Advanced Features

1. AI service deployment
2. Communication service (chat/video)
3. Third-party integrations
4. Performance optimization

### Phase 6: Production Readiness

1. Monitoring and alerting
2. Backup and disaster recovery
3. Security hardening
4. Load testing and optimization

## Success Criteria

- All 13 microservices deployed and communicating via gRPC
- MongoDB, Redis, and Kafka clusters operational
- Third-party API integrations working through NAT Gateway
- ArgoCD managing deployments with GitOps
- Monitoring and logging in place
- Auto-scaling based on load
- High availability across multiple AZs
- Security best practices implemented

## Questions to Address

1. Should we use managed services (RDS, ElastiCache, MSK) or self-hosted?
2. What's the preferred approach for secrets management?
3. Do we need service mesh (Istio) for this scale?
4. What's the disaster recovery strategy?
5. How should we handle database migrations?
6. What's the preferred monitoring stack?

Please help me create this infrastructure step by step, starting with the Terraform modules for the basic AWS infrastructure, then moving to the Kubernetes deployments, and finally setting up the CI/CD pipeline with ArgoCD.
