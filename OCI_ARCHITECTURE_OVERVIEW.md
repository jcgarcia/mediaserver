# OCI Architecture Overview for MediaServer

This document explains the architecture for deploying MediaServer on Oracle Cloud Infrastructure (OCI), including required components, creation steps, and how each part interacts within the system.

## Key OCI Components

1. **OCI Object Storage**
   - Stores uploaded media files (images, videos).
   - Interacts with MediaServer for file upload/download.
   - Equivalent to AWS S3.

2. **OCI Container Registry (OCIR)**
   - Stores Docker images for MediaServer.
   - Used by compute instances to pull the latest application image.
   - Equivalent to AWS ECR.

3. **OCI Compute (ARM/AMD VM or Container Instance)**
   - Runs the MediaServer application (Node.js).
   - Can be deployed as a VM, Container Instance, or Kubernetes (OKE).
   - Pulls images from OCIR and connects to Object Storage.

4. **OCI Networking (VCN, Subnets, Security Lists)**
   - Provides secure network connectivity for compute resources.
   - Controls inbound/outbound traffic to MediaServer and Object Storage.

5. **OCI Identity & Access Management (IAM)**
   - Manages user, group, and service permissions.
   - Required for secure access to Object Storage and Registry.

6. **OCI Secrets/Configuration Management**
   - Stores sensitive environment variables (JWT secrets, DB URIs).
   - Used by MediaServer at runtime.

7. **Database (Optional: OCI Autonomous DB, MySQL, MongoDB)**
   - Stores metadata about media files and users.
   - MediaServer connects via secure networking.

## How Components Interact

- **User uploads media** → MediaServer (running on Compute) → stores file in Object Storage.
- **MediaServer builds/deploys** → Docker image pushed to OCIR → Compute pulls image for deployment.
- **MediaServer authenticates users** → uses secrets/config from OCI Vault or environment.
- **MediaServer stores/retrieves metadata** → connects to database (Autonomous DB, MySQL, or MongoDB).
- **Networking** ensures only allowed traffic reaches MediaServer and Object Storage.
- **IAM** policies grant MediaServer access to Object Storage, Registry, and DB.

## What Needs to Be Created (Step-by-Step)

1. **Create OCI Object Storage Bucket**
   - For storing media files.
   - Set IAM policies for MediaServer access.

2. **Create OCIR Repository**
   - For storing Docker images.
   - Configure push/pull permissions.

3. **Build and Push Docker Image**
   - Build MediaServer Docker image locally.
   - Push to OCIR.

4. **Provision Compute Resource**
   - Create VM, Container Instance, or OKE cluster.
   - Configure to pull image from OCIR.
   - Set environment variables (secrets, config).

5. **Configure Networking**
   - Create VCN, subnets, and security lists.
   - Open required ports (e.g., 3000 for MediaServer).

6. **Set Up IAM Policies**
   - Grant MediaServer permissions for Object Storage, Registry, and DB.
   - Create dynamic groups and policies for compute resources.

7. **Create Database (Optional)**
   - Provision Autonomous DB, MySQL, or MongoDB.
   - Configure networking and credentials.

8. **Configure Secrets/Config Management**
   - Store sensitive data in OCI Vault or as environment variables.
   - Reference in MediaServer deployment.


## Example Architecture Diagram

```text
┌───────────────┐      ┌───────────────┐      ┌───────────────┐
│   Internet    │─────▶│  OCI Compute  │─────▶│ Object Storage│
└───────────────┘      └───────────────┘      └───────────────┘
   │                    │
   ▼                    ▼
┌───────────────┐      ┌───────────────┐
│   Database    │      │ OCI Registry │
└───────────────┘      └───────────────┘
```

## Automation & Deployment

- Use Terraform or OCI CLI to automate resource creation.
- Use Jenkins or OCI DevOps for CI/CD pipeline.
- Store infrastructure code and deployment scripts in the repository.


## References

- [OCI Object Storage](https://docs.oracle.com/en-us/iaas/Content/Object/home.htm)
- [OCI Container Registry](https://docs.oracle.com/en-us/iaas/Content/Registry/home.htm)
- [OCI Compute](https://docs.oracle.com/en-us/iaas/Content/Compute/home.htm)
- [OCI Networking](https://docs.oracle.com/en-us/iaas/Content/Network/home.htm)
- [OCI IAM](https://docs.oracle.com/en-us/iaas/Content/Identity/home.htm)
- [OCI Vault](https://docs.oracle.com/en-us/iaas/Content/KeyManagement/home.htm)
