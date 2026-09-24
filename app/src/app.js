const express = require('express');

const app = express();

// Middleware
app.use(express.json());

// Application metadata
const APP_NAME = "Cloud-Native DevSecOps Pipeline on AWS";
const APP_VERSION = process.env.APP_VERSION || "1.0.0";
const ENVIRONMENT = process.env.NODE_ENV || "production";
const GIT_COMMIT = process.env.GIT_COMMIT || "local-dev";
const START_TIME = new Date().toISOString();

// Root endpoint - Portfolio presentation landing
app.get('/', (req, res) => {
  res.status(200).json({
    project: APP_NAME,
    status: "online",
    environment: ENVIRONMENT,
    version: APP_VERSION,
    deployment: {
      gitCommit: GIT_COMMIT,
      startedAt: START_TIME,
      platform: "AWS ECS Fargate",
      containerEngine: "Docker",
      orchestrator: "Amazon Elastic Container Service",
      cloudProvider: "Amazon Web Services (AWS)"
    },
    securityFeatures: [
      "Keyless GitHub Actions OIDC Authentication",
      "Gitleaks Pre-commit Secret Scanning",
      "Semgrep Static Application Security Testing (SAST)",
      "Multi-stage Hardened Non-root Docker Container",
      "Trivy Container CVE Vulnerability Scanner",
      "VPC Isolated Private Subnet Execution",
      "AWS Secrets Manager Integration",
      "Amazon CloudWatch Centralized Logging & Alarms"
    ]
  });
});

// Health check endpoint for ALB target group & ECS health check
app.get('/health', (req, res) => {
  res.status(200).json({
    status: "healthy",
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Version endpoint for CI/CD smoke test validation
app.get('/version', (req, res) => {
  res.status(200).json({
    version: APP_VERSION,
    gitCommit: GIT_COMMIT,
    environment: ENVIRONMENT,
    nodeVersion: process.version
  });
});

module.exports = app;
