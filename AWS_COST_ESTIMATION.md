# MediaServer AWS Cost Estimation (2025)

## Overview

This post provides a practical cost estimation for running the MediaServer project on AWS, based on the resources provisioned by the Terraform automation and typical usage patterns. The Jenkins server is hosted on Oracle Cloud Infrastructure (OCI) and is always free, so only AWS costs are considered.

---

## AWS Components & Pricing

### 1. S3 Bucket (Media Storage)

- **Storage:** 100 GB (Standard)
- **Monthly Cost:** ~$2.30
- **Requests:** 100,000 PUT, 100,000 GET
- **Monthly Cost:** ~$0.10
- **Total S3:** **~$2.40/month**

### 2. ECR (Elastic Container Registry)

- **Storage:** 10 GB
- **Monthly Cost:** ~$1.20
- **Image Pulls/Pushes:** Negligible for small teams
- **Total ECR:** **~$1.20/month**

### 3. ECS (Fargate Cluster)

- **2 Tasks, 0.5 vCPU, 1GB RAM each, 24/7**
- **Monthly Cost (ARM/Graviton):** ~$16.00
- **Monthly Cost (x86/Intel/AMD):** ~$22.00
- **Load Balancer (ALB):** ~$18.00
- **Total ECS (ARM):** **~$34.00/month**
- **Total ECS (x86):** **~$40.00/month**

> **ARM/Graviton saves ~15-20% compared to x86 for compute costs. All MediaServer ECS tasks use ARM for optimal pricing and performance.**

### 4. IAM Roles, Policies, OIDC Provider

- **Cost:** Free (no charge for IAM resources)

### 5. Secrets Manager

- **5 secrets stored**
- **Monthly Cost:** ~$2.50

### 6. Data Transfer (Outbound)

- **1 TB/month outbound traffic**
- **Monthly Cost:** ~$90.00

---

## Estimated Monthly Total

| Service           | Estimated Cost (USD) |
|-------------------|---------------------|
| S3                | $2.40               |
| ECR               | $1.20               |
| ECS + ALB         | $34.00              |
| Secrets Manager   | $2.50               |
| Data Transfer     | $90.00              |
| **Total**         | **$130.10**         |

---

## Notes & Assumptions

- **Jenkins server is free on OCI.**
- **AWS Free Tier:** If eligible, some costs may be lower for the first 12 months.
- **Usage:** Estimates are for a small production deployment. Costs will scale with storage, compute, and data transfer.
- **Region:** Pricing based on eu-west-2 (London).
- **Other services (CloudFront, Lambda, etc.):** Not included unless explicitly used.

---

## Cost Optimization Tips

- Use ARM/Graviton instances for ECS (already optimized).
- Set up S3 lifecycle policies to reduce storage costs.
- Monitor data transfer and use CloudFront/CDN if needed.
- Clean up unused ECR images and secrets.

---

## Conclusion

A typical MediaServer deployment on AWS will cost **~$130/month** for the resources described above. Actual costs may vary based on usage, region, and optimizations. Always monitor your AWS billing dashboard for real-time costs.

---

_Last updated: August 2025_
