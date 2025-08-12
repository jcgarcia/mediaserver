# Important Note for Public Users

This guide is designed for clarity and reproducibility. If you are following these steps for your own project, please read each section carefully. The process for configuring AWS IAM roles is:

1. **Create the IAM role** (e.g., JenkinsMediaServerDeployRole) with the trust policy (OIDC provider and audience).
2. **After the role is created, attach all required permissions policies** (managed or custom) to the same role.

This two-step process is the standard and recommended AWS workflow. Do not try to add permissions policies and trust policy in the same step if the AWS console does not allow it; simply complete the role creation and then add permissions.

# Project-Specific Jenkins OIDC Access to AWS: Configuration Guide

This guide provides step-by-step instructions to securely configure Jenkins to access a specific AWS account for this project using OIDC, including all required IAM roles, policies, and Jenkins pipeline configuration.

---

## 1. Prerequisites
- Jenkins server with a public HTTPS URL (e.g., https://jenkins.ingasti.com)
- Jenkins OpenID Connect Provider Plugin installed and configured
- AWS CLI available in Jenkins build agents
- Administrative access to the target AWS account

---

## 2. Create the OIDC Identity Provider in AWS
1. Go to **IAM → Identity providers → Add provider**
2. **Provider type:** OpenID Connect
3. **Provider URL:** `https://jenkins.ingasti.com/oidc`
4. **Audience:** `sts.amazonaws.com`
5. Complete the wizard to create the provider

---



## 3. Create the IAM Role for Jenkins

### Step 1: Create the Role with Trust Policy
1. Go to **IAM → Roles → Create role**
2. **Trusted entity type:** Web identity
3. **Identity provider:** Select the OIDC provider you just created
4. **Audience:** `sts.amazonaws.com`
5. **Role name:** e.g., `JenkinsMediaServerDeployRole`
6. Complete the creation process. After the role is created, go to the **Trust relationships** tab and click **Edit trust policy**. Paste the following JSON:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/jenkins.ingasti.com/oidc"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "jenkins.ingasti.com/oidc:aud": "sts.amazonaws.com",
          "jenkins.ingasti.com/oidc:sub": "https://jenkins.ingasti.com/job/mediaserver/"
        }
      }
    }
  ]
}
```
- Replace `<ACCOUNT_ID>` with your AWS account ID.
- Adjust the `sub` claim to match your Jenkins job path (e.g., `job/mediaserver/`).

### Step 2: Attach Permissions Policies
1. In the **Permissions** tab of the same role, attach all required AWS managed or custom policies for your pipeline (e.g., ECS, ECR, S3, Secrets Manager, etc.).


2. **Required policies for this project:**

   Attach the following policies to the IAM role for Jenkins. These are required for the pipeline and deployment to work as provided in this repository:

   1. **Custom S3 policy** (for creating and managing the project bucket):

      ```json
      {
        "Version": "2012-10-17",
        "Statement": [
          {
            "Effect": "Allow",
            "Action": [
              "s3:CreateBucket",
              "s3:PutBucketPolicy",
              "s3:PutBucketTagging",
              "s3:ListAllMyBuckets",
              "s3:GetBucketLocation",
              "s3:PutEncryptionConfiguration",
              "s3:PutBucketVersioning",
              "s3:PutObject",
              "s3:GetObject"
            ],
            "Resource": [
              "arn:aws:s3:::mediaserver-pipeline-bucket",
              "arn:aws:s3:::mediaserver-pipeline-bucket/*"
            ]
          }
        ]
      }
      ```
      - This policy allows Jenkins to create and manage a bucket named `mediaserver-pipeline-bucket` only. If you want a different bucket name, change it in the policy and in your pipeline.

   2. **AWS managed policies:**
      - `AmazonECSFullAccess` (required for ECS deployment)
      - `AmazonEC2ContainerRegistryFullAccess` (required for pushing/pulling Docker images to ECR)
      - `SecretsManagerReadWrite` (required if your pipeline reads/writes secrets from AWS Secrets Manager)

   **Do not attach `AmazonS3FullAccess` or `AdministratorAccess`.**

   These policies are required for the provided pipeline and deployment to work. If you remove any of them, the project may fail to build or deploy.

**Summary:**
- The **trust policy** (with Principal) goes in the **Trust relationships** tab when you create the role.
- The **permissions policies** (with Resource) are attached in the **Permissions** tab after the role is created.

---

## 4. Configure Jenkins OIDC Credential
1. Go to **Manage Jenkins → Manage Credentials**
2. Add a new credential:
   - **Kind:** OpenID Connect id token as file
   - **ID:** `jenkins-oidc-mediaserver`
   - **Audience:** `sts.amazonaws.com`
   - (Issuer URI: leave blank for default)
3. Save the credential

---

## 5. Jenkins Pipeline Configuration
Add the following to your `Jenkinsfile` for this project:

```groovy
pipeline {
  agent any
  environment {
    AWS_ROLE_ARN = 'arn:aws:iam::<ACCOUNT_ID>:role/JenkinsMediaServerDeployRole'
    AWS_REGION = 'eu-west-2' // or your region
  }
  stages {
    stage('Deploy to AWS') {
      steps {
        withCredentials([file(credentialsId: 'jenkins-oidc-mediaserver', variable: 'AWS_WEB_IDENTITY_TOKEN_FILE')]) {
          sh '''
            export AWS_ROLE_ARN=$AWS_ROLE_ARN
            export AWS_WEB_IDENTITY_TOKEN_FILE=$AWS_WEB_IDENTITY_TOKEN_FILE
            aws sts get-caller-identity --region $AWS_REGION
            # Add your deployment commands here, e.g.:
            # aws ecs update-service ...
          '''
        }
      }
    }
  }
}
```
- Replace `<ACCOUNT_ID>` with your AWS account ID.
- Adjust the `credentialsId` and role name as needed.

---

## 6. Testing
- Run the pipeline. The `aws sts get-caller-identity` command should return the role ARN and account ID, confirming the OIDC connection is working.
- If you see an error, check the trust policy, audience, and sub claim in AWS, and ensure the Jenkins credential is correct.

---

## 7. Security Notes
- Restrict the IAM role permissions to only what is needed for this project.
- Use a unique OIDC credential and IAM role per project for least privilege.
- Rotate Jenkins OIDC signing keys periodically.

---

This guide ensures Jenkins can securely deploy to AWS for this project using OIDC, with all required AWS and Jenkins configuration steps included.
