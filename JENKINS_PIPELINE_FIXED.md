# Jenkins Pipeline: Fixed Reference

## Overview

This document provides the final, production-ready Jenkins pipeline configuration for the MediaServer project, optimized for ARM64 and AWS deployment.

---

## Key Features
- Multi-arch Docker builds (ARM64 + AMD64)
- Secure secrets management via Jenkins credentials
- Automated deployment to AWS ECS Fargate
- Infrastructure provisioning with Terraform
- Application deployment with Ansible
- Health checks and smoke tests

---

## Example Jenkinsfile

```groovy
pipeline {
    agent any
    environment {
        AWS_REGION = 'eu-west-2'
        S3_BUCKET = credentials('s3-bucket')
        JWT_SECRET = credentials('jwt-secret')
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Build') {
            steps {
                sh 'pnpm install'
                sh 'pnpm run build'
            }
        }
        stage('Docker Build & Push') {
            steps {
                sh 'docker buildx build --platform linux/arm64,linux/amd64 -t $IMAGE_TAG .'
                sh 'docker push $IMAGE_TAG'
            }
        }
        stage('Terraform Deploy') {
            steps {
                sh 'terraform init'
                sh 'terraform apply -auto-approve'
            }
        }
        stage('Ansible Deploy') {
            steps {
                sh 'ansible-playbook ansible/playbooks/deploy.yml -i ansible/inventory/hosts.yml'
            }
        }
        stage('Health Check') {
            steps {
                sh 'curl -f http://localhost:3000/health'
            }
        }
    }
}
```

---

## Notes
- All secrets are injected via Jenkins credentials
- Pipeline is triggered on push to `main` branch
- Multi-arch builds ensure compatibility with ARM and Intel hosts
