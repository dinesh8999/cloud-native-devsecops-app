# Cloud-Native DevSecOps Pipeline on AWS
## Viva Voce, Technical Evaluation & Interview Preparation Guide

This document is tailored for project presentations, viva examinations, and technical interviews. It covers architectural decisions, DevSecOps principles, AWS design justifications, and answers to common grilling questions.

---

### Part 1: High-Level 2-Minute Elevator Pitch

> "This project demonstrates an enterprise-grade Cloud-Native DevSecOps Pipeline deployed on AWS. Instead of treating security as a final pre-release checklist, this pipeline embeds automated security controls directly into the developer workflow. Whenever code is pushed to GitHub, automated unit tests, secret scanning with Gitleaks, SAST scanning with Semgrep, and container image vulnerability scanning with Trivy must pass before any cloud deployment occurs. 
> 
> Deployment authentication uses keyless OpenID Connect (OIDC) federation, eliminating static AWS access keys from GitHub Secrets. The application runs as an unprivileged non-root container on AWS ECS Fargate inside an isolated VPC, shielded behind an Application Load Balancer. All infrastructure is declared and reproducible using Terraform, with centralized logging and alarms powered by Amazon CloudWatch."

---

### Part 2: DevSecOps Fundamentals & Tools

#### 1. What does "Shift-Left" security mean, and how does this project implement it?
* **Answer:** "Shift-Left" means moving security checks earlier into the Software Development Life Cycle (SDLC), closer to the developer. In this project:
  - **Pre-commit / Pull Request:** Unit tests catch logic flaws.
  - **Secret Detection:** Gitleaks prevents API keys and credentials from ever being merged into Git history.
  - **Static Analysis (SAST):** Semgrep checks application code for dangerous injection vectors or insecure method calls before the code is even compiled into a container.
  - **Container Scanning:** Trivy scans the Docker image for operating system and library CVEs before pushing to Amazon ECR.
  - Catching issues here reduces the cost and blast radius of vulnerabilities compared to discovering them in production.

#### 2. Why use Semgrep instead of SonarQube?
* **Answer:** Semgrep is fast, lightweight, runs natively in CI/CD without requiring an external heavy server, and uses AST (Abstract Syntax Tree) pattern matching. Its rules can be declared as simple YAML definitions without proprietary configuration.

#### 3. Why use Trivy for container scanning?
* **Answer:** Trivy is an open-source vulnerability scanner specifically built for container images and OS packages. It checks OS package managers (Alpine `apk`, Debian `dpkg`) and language dependencies (npm `package-lock.json`) against known CVE databases. In our pipeline, it is configured with `exit-code: 1` on `CRITICAL` or `HIGH` vulnerabilities, creating an automated quality gate.

#### 4. Why use Gitleaks?
* **Answer:** Hardcoded secrets (AWS keys, database passwords, OAuth tokens) accidentally committed to Git repositories are one of the most common causes of cloud breaches. Gitleaks inspects git commit history and staging diffs using regex and entropy checks to catch and block leaks before deployment.

---

### Part 3: AWS Architecture & Cloud Security

#### 5. Why use GitHub OIDC instead of AWS Access Keys?
* **Answer:** 
  - **The Problem with Access Keys:** Static IAM access keys stored in GitHub Secrets are long-lived, do not rotate automatically, and can be exfiltrated if repository permissions are misconfigured.
  - **The OIDC Advantage:** With OpenID Connect (OIDC), GitHub Actions issues a short-lived JSON Web Token (JWT) signed by GitHub. AWS STS validates the JWT against the configured IAM Identity Provider and issues temporary AWS security credentials valid for only 1 hour. No secret keys ever exist in GitHub.

#### 6. What is the difference between the ECS Task Execution Role and the ECS Task Role?
* **Answer:**
  - **ECS Task Execution Role:** Used by the **AWS ECS infrastructure/agent** before the container starts. It needs permissions to pull images from Amazon ECR, stream logs to Amazon CloudWatch, and retrieve decrypted secrets from AWS Secrets Manager to inject as environment variables.
  - **ECS Task Role:** Used by the **application running inside the container** while it is alive. If the Express code needs to upload a file to Amazon S3 or query a DynamoDB table, those permissions are granted to the Task Role. In our project, following least privilege, the Task Role has minimal permissions.

#### 7. Why use AWS Fargate instead of EC2 for ECS?
* **Answer:**
  - **No Server Management:** Fargate is a serverless container compute engine. We do not need to patch the underlying Linux OS, manage EC2 AMIs, or handle cluster auto-scaling.
  - **Isolated MicroVMs:** Each Fargate task runs in its own dedicated virtual machine boundary, providing strong hardware-level isolation between tasks.
  - **Cost-Efficiency:** We pay strictly for the vCPU and memory consumed per second, avoiding idle EC2 instance costs.

#### 8. How does the Application Load Balancer and VPC design enforce security?
* **Answer:**
  - The ALB is placed in the **public subnets** with an Internet Gateway, listening on port 80.
  - The **ECS Fargate tasks** have their security group configured to allow inbound traffic **strictly on port 3000 originating from the ALB's security group ID**.
  - Direct access from the internet to container ports is blocked by the AWS Security Group firewall.

---

### Part 4: Docker & Container Hardening

#### 9. Why is the Dockerfile multi-stage?
* **Answer:**
  - In Stage 1 (`builder`), we install npm dependencies.
  - In Stage 2 (`runner`), we copy only the compiled `node_modules` and application source files.
  - This keeps build tools, caches, and unnecessary binaries out of the final container, drastically reducing image size (from ~300MB to ~80MB) and shrinking the vulnerability attack surface.

#### 10. Why run the container as an unprivileged user (`node`)?
* **Answer:** By default, Docker containers run as `root` (UID 0). If a vulnerability inside the web application allows remote code execution (RCE), an attacker with root privileges in the container might exploit kernel flaws or container escape vulnerabilities. Running as the unprivileged user `node` (UID 1000) limits the attacker's capabilities within the container namespace.

---

### Part 5: Terraform & Infrastructure as Code

#### 11. What is the difference between `terraform plan` and `terraform apply`?
* **Answer:**
  - `terraform plan` is a read-only speculative execution that compares the desired state declared in `.tf` files with the real-world infrastructure recorded in the state file and live AWS APIs. It creates an execution plan detailing what resources will be created, modified, or destroyed.
  - `terraform apply` actually executes the plan against AWS APIs to bring the real infrastructure into alignment with the code.

#### 12. Why enable Image Tag Immutability in Amazon ECR?
* **Answer:** If tags are mutable, a developer or compromised build could overwrite the `:latest` or `:v1.0.0` tag with different container code, making rollbacks unpredictable and violating audit integrity. With immutability enabled, each build must push a unique tag (such as the Git commit SHA), ensuring that every deployed artifact is traceable and tamper-proof.

---

### Part 6: Controlled Failure Demonstrations

When presenting the project, you can demonstrate the following 6 test scenarios to prove your security gates function:

1. **Happy Path:** Clean push $\to$ all 5 GitHub Actions stages pass $\to$ ECS service updates $\to$ ALB returns 200 OK.
2. **Broken Unit Test:** Introduce `expect(response.status).toBe(500)` in `app.test.js` $\to$ Stage 1 fails $\to$ deployment blocked.
3. **Leaked Secret:** Introduce `AWS_KEY = "AKIAIOSFODNN7EXAMPLE"` $\to$ Stage 2 Gitleaks fails $\to$ deployment blocked.
4. **Dangerous Code (SAST):** Introduce `eval(req.query.cmd)` in `server.js` $\to$ Stage 3 Semgrep fails $\to$ deployment blocked.
5. **Container CVE:** Introduce an outdated base image or vulnerable package $\to$ Stage 4 Trivy fails with exit code 1 $\to$ image never pushed to ECR.
6. **Remediation:** Remove the offending line $\to$ push $\to$ green pipeline and successful zero-downtime deployment.
