# Cloud-Native DevSecOps Pipeline on AWS: Status & Next Steps

This document outlines the current state of the repository, completed components, pending configurations, and the step-by-step roadmap to deploy, verify, and demonstrate the DevSecOps pipeline.

---

## 1. Project Health & Architecture Overview

The codebase is fully structured and prepared with shift-left security controls, automated container packaging, keyless cloud authentication, and infrastructure as code (IaC).

```mermaid
flowchart TD
    subgraph CI_CD["GitHub Actions CI/CD (devsecops.yml)"]
        A[Git Push / PR] --> B[1. Unit Tests: Jest]
        B --> C[2. Secret Scan: Gitleaks]
        C --> D[3. SAST: Semgrep]
        D --> E[4. Container CVE Scan: Trivy]
        E --> F[5. AWS OIDC Keyless Login]
        F --> G[Push to Amazon ECR]
        F --> H[Rolling Update Amazon ECS Fargate]
    end

    subgraph AWS_Cloud["AWS Infrastructure (Terraform)"]
        G -.-> ECR_Repo[(Amazon ECR)]
        H -.-> ECS_Service[ECS Fargate Service]
        ALB[Application Load Balancer] -->|Port 3000| ECS_Service
        ECS_Service --> Secrets[AWS Secrets Manager]
        ECS_Service --> CW[CloudWatch Logs & Alarms]
    end
```

---

## 2. Component Status Matrix

| Component | Path | Status | Notes |
| :--- | :--- | :---: | :--- |
| **Microservice App** | [app.js](file:///d:/Projects/MyWork/aws-native-pipeline/app/src/app.js) | ✅ Complete | Node.js 20 Express (`/`, `/health`, `/version`) |
| **Unit & Integration Tests**| [app.test.js](file:///d:/Projects/MyWork/aws-native-pipeline/app/test/app.test.js) | ✅ Complete | Jest & Supertest endpoint tests |
| **Containerization** | [Dockerfile](file:///d:/Projects/MyWork/aws-native-pipeline/Dockerfile) | ✅ Complete | Multi-stage, Alpine, non-root user `node` |
| **Secret Scanning Policy** | [.gitleaks.toml](file:///d:/Projects/MyWork/aws-native-pipeline/.gitleaks.toml) | ✅ Complete | Regex rules for tokens, private keys, API keys |
| **SAST Security Rules** | [semgrep.yml](file:///d:/Projects/MyWork/aws-native-pipeline/security/semgrep.yml) | ✅ Complete | Rules for `eval()`, hardcoded JWTs, cmd injection |
| **Container CVE Policy** | [trivy.yaml](file:///d:/Projects/MyWork/aws-native-pipeline/security/trivy.yaml) | ✅ Complete | Fail build on `CRITICAL` or `HIGH` vulnerabilities |
| **CI/CD Automation** | [devsecops.yml](file:///d:/Projects/MyWork/aws-native-pipeline/.github/workflows/devsecops.yml) | ✅ Complete | 5-stage automated pipeline with OIDC deploy |
| **Terraform IaC Modules** | [terraform/](file:///d:/Projects/MyWork/aws-native-pipeline/terraform) | ✅ Complete | VPC, ALB, ECR, ECS Fargate, IAM OIDC, Secrets, CW |
| **Variable Configuration** | `terraform.tfvars` | ⏳ Pending | Needs creation from `terraform.tfvars.example` |
| **AWS Cloud Resources** | AWS Account | ⏳ Pending | Requires running `terraform apply` |
| **GitHub Secret Setup** | GitHub Repo Settings | ⏳ Pending | Requires setting `AWS_ROLE_ARN` in GitHub |

---

## 3. Step-by-Step Next Actions

### Step 1: Configure Terraform Variables
Create `terraform/terraform.tfvars` from [terraform.tfvars.example](file:///d:/Projects/MyWork/aws-native-pipeline/terraform/terraform.tfvars.example):

```hcl
aws_region   = "us-east-1"
project_name = "cloud-native-devsecops"
environment  = "prod"
github_repo  = "YOUR_GITHUB_USERNAME/YOUR_REPO_NAME"
```

> [!IMPORTANT]
> Ensure `github_repo` matches your exact GitHub `owner/repository` string. The IAM OIDC Trust Relationship uses this string in `repo:owner/repo:*` to validate tokens.

---

### Step 2: Provision Infrastructure on AWS
Navigate into the `terraform/` directory with your terminal (configured with valid AWS credentials):

```bash
cd terraform
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Take note of the output values printed upon completion:
* `github_actions_role_arn` (e.g. `arn:aws:iam::123456789012:role/cloud-native-devsecops-github-actions-role`)
* `alb_dns_name` (e.g. `cloud-native-devsecops-alb-123456.us-east-1.elb.amazonaws.com`)
* `ecr_repository_url`

---

### Step 3: Add the GitHub Actions Secret
1. Open your repository in GitHub.
2. Navigate to **Settings** ➔ **Secrets and variables** ➔ **Actions**.
3. Click **New repository secret**.
   - **Name:** `AWS_ROLE_ARN`
   - **Value:** `<Paste the github_actions_role_arn value from Step 2>`

---

### Step 4: Push to GitHub & Trigger DevSecOps Pipeline
Commit all files and push to your `main` branch:

```bash
git add .
git commit -m "feat: configure and trigger devsecops pipeline"
git push origin main
```

Monitor the run in the **Actions** tab on GitHub:
- [x] Stage 1: `1. Unit Tests`
- [x] Stage 2: `2. Secret Scan (Gitleaks)`
- [x] Stage 3: `3. SAST Scan (Semgrep)`
- [x] Stage 4: `4. Container Build & CVE Scan (Trivy)`
- [x] Stage 5: `5. Deploy to AWS ECS (Fargate)`

---

### Step 5: Verify Live Endpoints
Once the pipeline shows green, query the Application Load Balancer:

```bash
# Landing summary
curl http://<ALB_DNS_NAME>/

# Health check
curl http://<ALB_DNS_NAME>/health

# Version & commit hash
curl http://<ALB_DNS_NAME>/version
```

---

## 4. Controlled Security Failure Demonstrations (Viva & Demos)

To demonstrate how the pipeline actively blocks insecure code, run these controlled test cases on feature branches:

| Demo Case | Trigger Action | Expected Gate Reaction |
| :--- | :--- | :--- |
| **1. Unit Test Failure** | Change test expectation to `expect(200).toBe(500)` in `app.test.js` | **Stage 1 fails**: Pipeline aborts before scans run |
| **2. Secret Leak** | Add `AWS_SECRET = "AKIAIOSFODNN7EXAMPLE"` in any file | **Stage 2 fails**: Gitleaks rejects the commit |
| **3. SAST Violation** | Add `eval(req.query.cmd)` into `app.js` | **Stage 3 fails**: Semgrep rule `express-eval-injection` flags RCE |
| **4. Vulnerable Container** | Change base image in `Dockerfile` to an unpatched old image | **Stage 4 fails**: Trivy detects CVEs and halts deployment |
| **5. Clean Recovery** | Revert the test code and push clean commit | **All Stages Pass**: Deploys cleanly to AWS Fargate |

---

## 5. Cost Cleanup & Teardown

When testing or evaluation is complete, destroy all cloud resources to eliminate AWS charges:

```bash
cd terraform
terraform destroy -auto-approve
```
