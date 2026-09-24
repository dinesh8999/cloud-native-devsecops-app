# Cloud-Native DevSecOps Pipeline on AWS

[![DevSecOps Pipeline](https://github.com/OWNER/REPO/actions/workflows/devsecops.yml/badge.svg)](https://github.com/OWNER/REPO/actions/workflows/devsecops.yml)
[![Security Scan: Gitleaks](https://img.shields.io/badge/Secret%20Scan-Gitleaks-blue)](https://github.com/gitleaks/gitleaks)
[![SAST: Semgrep](https://img.shields.io/badge/SAST-Semgrep-green)](https://semgrep.dev/)
[![Container: Trivy](https://img.shields.io/badge/Vulnerability%20Scan-Trivy-orange)](https://aquasecurity.github.io/trivy/)
[![Cloud: AWS Fargate](https://img.shields.io/badge/AWS-ECS%20Fargate-FF9900?logo=amazon-aws)](https://aws.amazon.com/fargate/)
[![IaC: Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC?logo=terraform)](https://www.terraform.io/)

---

## 1. Project Overview & Problem Statement

Modern software teams need to deliver features rapidly without introducing critical security vulnerabilities, credential leaks, or configuration drift into cloud production environments. 

This project provides an end-to-end, enterprise-grade, **Cloud-Native DevSecOps CI/CD Platform on Amazon Web Services (AWS)**. It demonstrates "Shift-Left" security by integrating automated unit testing, secret scanning (**Gitleaks**), static application security testing (**Semgrep**), and container image vulnerability scanning (**Trivy**) into every Git commit. 

The deployment leverages keyless authentication via **GitHub Actions OIDC**, stores immutable images in **Amazon ECR**, and orchestrates zero-downtime rolling updates to **Amazon ECS (AWS Fargate)** running behind an **Application Load Balancer (ALB)** in an isolated VPC. All infrastructure is declared in **Terraform**.

---

## 2. Target Architecture

```
Developer (git push / PR)
       │
       ▼
GitHub Repository
       │
       ▼
GitHub Actions CI/CD Pipeline
       ├── 1. Automated Unit Tests (Jest & Supertest)
       ├── 2. Secret Scanning Gate (Gitleaks)
       ├── 3. Static Code Analysis / SAST (Semgrep)
       ├── 4. Hardened Multi-Stage Docker Build
       ├── 5. Container CVE Scanning Gate (Trivy: CRITICAL/HIGH exit-code: 1)
       └── 6. Short-Lived AWS STS Token (OIDC Keyless Federation)
                  │
                  ├──► Push Immutable Image Tag (Git SHA) ──► Amazon ECR
                  │                                               │
                  └──► Zero-Downtime Rolling Update ────────┐     │
                                                            ▼     ▼
                                                 Amazon ECS Fargate Cluster
                                                            │
┌────────────────────────────── AWS Custom VPC ─────────────┼─────────────────────────────┐
│                                                           │                             │
│   ┌──────────────── Public Subnets ───────────────────┐   │                             │
│   │                                                   │   │                             │
│   │   [ Internet Gateway ]                            │   │                             │
│   │          │                                        │   │                             │
│   │          ▼                                        │   │                             │
│   │   [ Application Load Balancer (Port 80) ]         │   │                             │
│   │          │                                        │   │                             │
│   └──────────┼────────────────────────────────────────┘   │                             │
│              │ (Forward Port 3000)                        │                             │
│              ▼                                            │                             │
│   ┌──────────────── Subnet Security Group ────────────────┼──────────────────────────┐  │
│   │                                                       ▼                          │  │
│   │     [ ECS Fargate Service: Node.js Express Container (Non-root user node) ]      │  │
│   │                           │                                                      │  │
│   │                           ├────────────────────────┐                             │  │
│   └───────────────────────────┼────────────────────────┼─────────────────────────────┘  │
└───────────────────────────────┼────────────────────────┼────────────────────────────────┘
                                ▼                        ▼
                    [ AWS Secrets Manager ]     [ Amazon CloudWatch ]
                   (Encrypted API Credentials)  (Logs, Alarms & Metrics)
```

---

## 3. Technology Stack & AWS Services

| Domain | Technology / Service | Purpose |
| :--- | :--- | :--- |
| **Application Runtime** | Node.js 20 LTS, Express.js | Microservice API (`/`, `/health`, `/version`) |
| **Test Automation** | Jest, Supertest | Unit & endpoint integration tests |
| **Container Engine** | Docker, Alpine Linux | Multi-stage, non-root, minimal surface build |
| **Secret Detection** | Gitleaks | Blocks commits containing API keys, private keys, passwords |
| **SAST** | Semgrep | Detects eval injection, hardcoded secrets, insecure APIs |
| **Container Scanning**| Aqua Security Trivy | Blocks images containing CRITICAL/HIGH CVEs |
| **CI/CD Platform** | GitHub Actions | Keyless continuous integration & deployment automation |
| **Cloud Authentication**| AWS IAM + GitHub OIDC | Zero long-lived secret keys stored in GitHub |
| **Container Registry**| Amazon ECR | Private registry with tag immutability and scan-on-push |
| **Container Compute** | Amazon ECS & AWS Fargate | Serverless container execution |
| **Networking** | Amazon VPC, ALB, Subnets | Public load balancer, security group isolation |
| **Secrets Engine** | AWS Secrets Manager | Injection of encrypted runtime credentials |
| **Observability** | Amazon CloudWatch | Application streaming logs and CPU/Memory alarms |
| **Infrastructure as Code**| Terraform (HCL) | 100% reproducible cloud provisioning |

---

## 4. Repository Structure

```
cloud-native-devsecops-aws/
├── app/
│   ├── src/
│   │   ├── app.js               # Express application routes & security metadata
│   │   └── server.js            # Server entry point & graceful shutdown hooks
│   ├── test/
│   │   └── app.test.js          # Automated endpoint integration tests
│   ├── package.json             # NPM dependencies & scripts
│   └── package-lock.json
│
├── .github/
│   └── workflows/
│       └── devsecops.yml        # GitHub Actions OIDC + DevSecOps CI/CD pipeline
│
├── terraform/
│   ├── providers.tf             # AWS provider configuration
│   ├── variables.tf             # Input variables (region, CIDRs, sizing)
│   ├── outputs.tf               # Infrastructure outputs (ALB DNS, ECR URL)
│   ├── vpc.tf                   # VPC, Subnets, IGW, Route Tables
│   ├── security_groups.tf       # ALB and ECS Task least-privilege security groups
│   ├── ecr.tf                   # ECR repository with scan-on-push & lifecycle rules
│   ├── alb.tf                   # ALB, Target Group, and HTTP listener
│   ├── ecs.tf                   # ECS Cluster, Task Definition, Fargate Service
│   ├── iam.tf                   # GitHub OIDC Role, ECS Execution & Task Roles
│   ├── secrets.tf               # AWS Secrets Manager configuration
│   ├── cloudwatch.tf            # Log Group (7-day retention) & Metric Alarms
│   └── terraform.tfvars.example # Sample variable values
│
├── security/
│   ├── semgrep.yml              # SAST rule definitions (Injection, Secrets, Eval)
│   └── trivy.yaml               # Vulnerability scanning policy & severity thresholds
│
├── .gitleaks.toml               # Custom Gitleaks scanning configuration
├── Dockerfile                   # Hardened multi-stage Docker build
├── .dockerignore                # Strict build context exclusions
├── .gitignore                   # Version control exclusions
└── README.md                    # Project documentation
```

---

## 5. Security Controls & Architecture Deep Dive

### A. Keyless GitHub Actions Authentication (OIDC)
* **The Risk:** Storing long-lived `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` in GitHub Secrets creates an ongoing risk of token exfiltration.
* **The Solution:** We create an **IAM OpenID Connect Identity Provider** pointing to `token.actions.githubusercontent.com`. GitHub Actions requests a short-lived JSON Web Token (JWT) signed by GitHub, and AWS STS exchanges this for a temporary 1-hour session. The IAM role trust policy restricts access strictly to the exact GitHub repository (`repo:username/repo:*`).

### B. Fail-Closed DevSecOps Security Gates
* **Stage 1 (Unit Tests):** If any unit test fails, pipeline terminates immediately.
* **Stage 2 (Gitleaks):** Analyzes entire Git commit history. If an AWS key, private key, or credential pattern is detected, the run is rejected.
* **Stage 3 (Semgrep SAST):** Scans Javascript AST for dangerous patterns like `eval()`, command injection via `child_process.exec()`, or unescaped injection points.
* **Stage 4 (Trivy Container Scan):** Inspects all OS packages (Alpine) and language dependencies (npm). If a vulnerability of severity `CRITICAL` or `HIGH` is unpatched, the build fails (`exit-code: 1`), preventing the image from reaching Amazon ECR.

### C. Container Hardening
* **Multi-Stage Build:** Dependencies are installed in a separate `builder` stage, keeping compiler artifacts out of the final runtime container.
* **Non-Root Execution:** Container switches to `USER node` (UID 1000). If an application vulnerability is compromised, the attacker cannot gain root access to the container namespace.
* **Minimal Base:** Built on `node:20-alpine` with package caches removed (`rm -rf /var/cache/apk/*`).

### D. Network Segmentation
* The **ECS Fargate Tasks** run inside isolated subnets with security groups configured to accept ingress traffic **strictly on port 3000 originating from the ALB Security Group ID**. Direct internet access to the container port is impossible.

---

## 6. Controlled Failure Demonstrations

To prove that the pipeline security controls work effectively in real-world scenarios, execute the following controlled demonstrations:

| Test Case | Introduced Condition | Expected Result | Pipeline Gate |
| :--- | :--- | :--- | :--- |
| **Test 1: Normal Flow** | Clean commit with passing tests | Pipeline succeeds; deploys to ECS | All Passed |
| **Test 2: Broken Test** | Modify test assertion to `expect(200).toBe(500)` | Build halted at Stage 1 | Unit Tests |
| **Test 3: Secret Leak** | Add `AWS_SECRET_KEY = "AKIAIOSFODNN7EXAMPLE"` | Build halted at Stage 2 | Gitleaks |
| **Test 4: SAST Violation**| Add `eval(req.query.cmd)` to `server.js` | Build halted at Stage 3 | Semgrep |
| **Test 5: Container CVE** | Downgrade base to outdated image with known CVEs | Build halted at Stage 4 | Trivy |
| **Test 6: Recovery** | Remove vulnerabilities and push fix | Pipeline recovers; deploys to ECS | All Passed |

---

## 7. Step-by-Step Deployment Instructions

### Prerequisites
* AWS Account with Administrator access for initial provisioning
* AWS CLI v2 installed (`aws configure`)
* Terraform >= 1.5.0 installed
* GitHub Account

### Step 1: Clone and Configure Repository
```bash
git clone <your-github-repo-url>
cd aws-native-pipeline
```

### Step 2: Initialize Infrastructure with Terraform
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```
Edit `terraform.tfvars` and set your GitHub repository:
```hcl
github_repo = "your-github-username/your-repo-name"
```

Plan and apply:
```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Note the outputs from Terraform:
* `ecr_repository_url`
* `alb_dns_name`
* `github_actions_role_arn`

### Step 3: Configure GitHub Repository Secrets
In your GitHub Repository, navigate to **Settings > Secrets and variables > Actions** and add:
* **Secret Name:** `AWS_ROLE_ARN`
* **Secret Value:** `<output of github_actions_role_arn>`

### Step 4: Push Application Code to Trigger Pipeline
```bash
git add .
git commit -m "feat: initial devsecops pipeline configuration"
git push origin main
```
Navigate to the **Actions** tab on GitHub to monitor the DevSecOps pipeline execution.

### Step 5: Verify Deployment
Open your browser or run curl against the ALB DNS Name:
```bash
curl http://<ALB_DNS_NAME>/
curl http://<ALB_DNS_NAME>/health
curl http://<ALB_DNS_NAME>/version
```

---

## 8. Monitoring & Observability

* **CloudWatch Logs:** Container `stdout` and `stderr` are streamed to `/ecs/cloud-native-devsecops-app`.
* **Health Checks:** The ALB target group evaluates `/health` every 30 seconds. Unhealthy tasks are automatically terminated and replaced by ECS.
* **Alarms:** Configured for CPUUtilization > 80% and MemoryUtilization > 80%.

---

## 9. Cost Optimization & Cleanup

To avoid continuous AWS charges after completing evaluation:

```bash
cd terraform
terraform destroy -auto-approve
```
*Resources deleted:* ALB, ECS Cluster & Service, CloudWatch Log Group, Secrets Manager Secret, ECR Repository, VPC, and Subnets.
