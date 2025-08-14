docker tag mediaserver:oci $OCIR_REPO:latest
docker push $OCIR_REPO:latest

# OCI Build & Deployment Guide for MediaServer

This guide provides a concise step-by-step checklist to build and deploy the OCI version of MediaServer.

---

## Pre-Deployment Checklist

- [ ] OCI account with required permissions
- [ ] OCI Object Storage bucket created
- [ ] OCI Container Registry (OCIR) repository created
- [ ] Compute resource (VM, Container Instance, or OKE) provisioned
- [ ] Networking (VCN, subnets, security lists) configured
- [ ] IAM policies for Object Storage, Registry, and Compute set
- [ ] Database (optional) provisioned and accessible
- [ ] Secrets/configuration stored in OCI Vault or environment
- [ ] Jenkins/CI/CD pipeline configured (optional)

---

## Step-by-Step Build & Deployment

### 1. Build Docker Image

```bash
# On your local machine
docker build -t mediaserver:oci .
```

### 2. Tag & Push Image to OCIR

```bash
# Log in to OCIR
docker login <region>.ocir.io -u 'tenancy/username' -p '<auth_token>'

# Tag image
export OCIR_REPO=<region>.ocir.io/<tenancy>/mediaserver

docker tag mediaserver:oci $OCIR_REPO:latest

# Push image
docker push $OCIR_REPO:latest
```

### 3. Provision Compute Resource

- Create a VM, Container Instance, or OKE cluster in OCI Console.
- Configure to pull the image from OCIR.
- Set environment variables (secrets, config).

### 4. Configure Networking

- Open required ports (e.g., 3000 for MediaServer).
- Ensure security lists allow inbound traffic.

### 5. Set Up IAM Policies

- Grant compute resource access to Object Storage and Registry.
- Use dynamic groups and policies for automation.

### 6. Deploy MediaServer

- Pull Docker image from OCIR on compute resource.
- Run container with environment variables:

```bash
docker run -d --name mediaserver \
  -e S3_BUCKET_NAME=<oci_bucket> \
  -e JWT_SECRET=<jwt_secret> \
  -e MONGODB_URI=<db_uri> \
  -p 3000:3000 $OCIR_REPO:latest
```

### 7. Test Application

- Access MediaServer at `http://<compute_public_ip>:3000`
- Upload media, check Object Storage, and verify DB connectivity.

---

## Troubleshooting

- Check OCI Console for resource status and logs.
- Use `docker logs mediaserver` for container output.
- Verify IAM policies and networking if access fails.

---

## References

- [OCI Object Storage](https://docs.oracle.com/en-us/iaas/Content/Object/home.htm)
- [OCI Container Registry](https://docs.oracle.com/en-us/iaas/Content/Registry/home.htm)
- [OCI Compute](https://docs.oracle.com/en-us/iaas/Content/Compute/home.htm)
- [OCI Networking](https://docs.oracle.com/en-us/iaas/Content/Network/home.htm)
- [OCI IAM](https://docs.oracle.com/en-us/iaas/Content/Identity/home.htm)
- [OCI Vault](https://docs.oracle.com/en-us/iaas/Content/KeyManagement/home.htm)
