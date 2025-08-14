# Jenkins OIDC Provider Setup on AWS

## Overview

This guide explains how to set up an OpenID Connect (OIDC) provider in AWS for Jenkins, enabling secure, credential-free access for your CI/CD pipeline.

---

## Steps

1. **Create OIDC Provider in AWS IAM**
   - Go to AWS Console → IAM → Identity Providers → Add Provider
   - Provider Type: OpenID Connect
   - Provider URL: `https://<your-jenkins-url>/securityRealm/oidc` (replace with your Jenkins URL)
   - Audience: `sts.amazonaws.com`

2. **Configure Trust Policy for Jenkins IAM Role**
   - Attach a trust policy to allow Jenkins OIDC provider to assume the role
   - Example trust policy:
     ```json
     {
       "Effect": "Allow",
       "Principal": {
         "Federated": "arn:aws:iam::<account-id>:oidc-provider/<jenkins-oidc-url>"
       },
       "Action": "sts:AssumeRoleWithWebIdentity"
     }
     ```

3. **Attach Required Policies to the Role**
   - AmazonECSFullAccess
   - AmazonEC2ContainerRegistryFullAccess
   - SecretsManagerReadWrite
   - Custom S3 policy for your bucket

4. **Test OIDC Integration**
   - Use Jenkins OIDC plugin to authenticate and assume the AWS role
   - Run a test pipeline to verify access

---

## References
- [AWS OIDC Provider Docs](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
- [Jenkins OIDC Plugin](https://plugins.jenkins.io/oidc-provider/)
