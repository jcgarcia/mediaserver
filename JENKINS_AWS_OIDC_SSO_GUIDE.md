# Jenkins AWS OIDC SSO Integration Guide

## Overview

This guide explains how to configure Jenkins for Single Sign-On (SSO) with AWS using OpenID Connect (OIDC), enabling secure, federated access for CI/CD pipelines.

---

## Steps

1. **Install Jenkins OIDC Plugin**
   - Go to Jenkins → Manage Plugins → Search for "OIDC Provider"
   - Install and restart Jenkins

2. **Configure OIDC Provider in Jenkins**
   - Go to Jenkins → Manage Jenkins → Configure Global Security
   - Set up OIDC provider with your Jenkins URL

3. **Create OIDC Identity Provider in AWS IAM**
   - See [JENKINS_OIDC_PROVIDER_AWS_GUIDE.md](JENKINS_OIDC_PROVIDER_AWS_GUIDE.md)

4. **Configure IAM Role Trust Policy**
   - Allow Jenkins OIDC provider to assume the role

5. **Test SSO Integration**
   - Run a Jenkins job that authenticates to AWS using OIDC

---

## Troubleshooting
- Ensure Jenkins and AWS clocks are synchronized
- Check IAM trust policy for correct OIDC provider ARN
- Review Jenkins logs for authentication errors

---

## References
- [Jenkins OIDC Plugin](https://plugins.jenkins.io/oidc-provider/)
- [AWS OIDC Docs](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
