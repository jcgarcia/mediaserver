docker tag mediaserver:oci $OCIR_REPO:latest
docker push $OCIR_REPO:latest


# OCI Build & Deployment Guide for MediaServer

This guide provides a concise step-by-step checklist to build and deploy the OCI version of MediaServer.

---


## OCI CLI Installation & Configuration

## Automating OCI CLI Parameters with a Shell Wrapper

## Jenkins Automation: Secure OCI CLI Usage

## Jenkins CLI Credential Creation: Step-by-Step

## Sample Jenkins Pipeline: OCI Credential Usage

Below is a sample Jenkins pipeline that references all required OCI credentials and tests their availability:

```groovy
pipeline {
  agent any
  environment {
    OCI_USER_OCID = credentials('oci-user-ocid')
    OCI_TENANCY_OCID = credentials('oci-tenancy-ocid')
    OCI_COMPARTMENT_OCID = credentials('oci-compartment-ocid')
    OCI_KEY_FINGERPRINT = credentials('oci-key-fingerprint')
    OCI_REGION = credentials('oci-region')
    OCI_KEY_FILE = credentials('oci-key-file')
    OCI_AUTH_TOKEN = credentials('oci-auth-token')
  }
  stages {
    stage('Test Credentials') {
      steps {
        sh '''
          echo "OCI_USER_OCID: $OCI_USER_OCID"
          echo "OCI_TENANCY_OCID: $OCI_TENANCY_OCID"
          echo "OCI_COMPARTMENT_OCID: $OCI_COMPARTMENT_OCID"
          echo "OCI_KEY_FINGERPRINT: $OCI_KEY_FINGERPRINT"
          echo "OCI_REGION: $OCI_REGION"
          echo "OCI_KEY_FILE: $OCI_KEY_FILE"
          echo "OCI_AUTH_TOKEN: $OCI_AUTH_TOKEN"
        '''
      }
    }
    // Add further stages for OCI CLI usage as needed
  }
}
```

This pipeline will print all credential values (except file contents) to verify they are injected correctly. For file credentials, `$OCI_KEY_FILE` will be the path to the uploaded file.

---
This section documents the exact process for creating Jenkins credentials for OCI automation using the Jenkins CLI and XML files.

### 1. Prepare XML Credential Files

For each secret text credential, use the following format (example for User OCID):

```xml
<org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>oci-user-ocid</id>
  <description>OCI User OCID</description>
  <secret>ocid1.user.oc1..xxxx</secret>
</org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl>
```

Repeat for each value (tenancy, compartment, fingerprint, region, etc.), changing the `<id>`, `<description>`, and `<secret>` as needed.

### 2. Create Credentials via Jenkins CLI

Run the following command for each XML file:

```bash
jenkins-prod create-credentials-by-xml system::system::jenkins _ < /path/to/your-credential.xml
```

Where:
- `system::system::jenkins` is the global credentials store
- `_` is the global domain
- `/path/to/your-credential.xml` is the XML file you prepared

### 3. Verify Credentials

List credentials to confirm creation:

```bash
jenkins-prod list-credentials system::system::jenkins
```

### 4. Troubleshooting

- Use the correct XML class: `<org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl>` for secret text.
- Only one credential per XML file.
- If you see `CannotResolveClassException`, check the class name and ensure the required plugin is installed (`plain-credentials`).
- Export existing credentials as XML for reference:
  ```bash
  jenkins-prod list-credentials-as-xml system::system::jenkins
  ```

---
## OCI & Jenkins Credential Reference

Below is a table of all required values, where to find them, and how to configure them in Jenkins.

| Credential Name         | Type         | Where to Find / How to Generate                                                                 | Jenkins Type      |
|------------------------|--------------|-------------------------------------------------------------------------------------------------|-------------------|
| oci-user-ocid          | OCID         | OCI Console → Identity → Users → Click your user → Copy OCID                                   | Secret Text       |
| oci-tenancy-ocid       | OCID         | OCI Console → Administration → Tenancy Details → Copy OCID                                     | Secret Text       |
| oci-compartment-ocid   | OCID         | OCI Console → Identity → Compartments → Click your compartment → Copy OCID                     | Secret Text       |
| oci-key-file           | File         | Path in config file (key_file=...), usually ~/.ssh/OCI-API.pem. Upload file to Jenkins.         | Secret File       |
| oci-key-fingerprint    | Fingerprint  | OCI Console → Identity → Users → API Keys → Copy Fingerprint                                  | Secret Text       |
| oci-region             | Region Name  | In config file (region=...), or top bar in OCI Console                                         | Secret Text       |
| oci-auth-token         | Auth Token   | OCI Console → Identity → Users → Auth Tokens → Generate Token                                 | Secret Text       |

### Checklist: Prepare All Required Values

1. **User OCID**
  - Go to OCI Console → Identity → Users
  - Click your user
  - Copy the OCID
  - Add to Jenkins as `oci-user-ocid` (Secret Text)

2. **Tenancy OCID**
  - Go to OCI Console → Administration → Tenancy Details
  - Copy the OCID
  - Add to Jenkins as `oci-tenancy-ocid` (Secret Text)

3. **Compartment OCID**
  - Go to OCI Console → Identity → Compartments
  - Click your compartment
  - Copy the OCID
  - Add to Jenkins as `oci-compartment-ocid` (Secret Text)

4. **API Key File**
  - Find the path in your config file (`key_file=...`)
  - Upload the private key file to Jenkins as `oci-key-file` (Secret File)

5. **Key Fingerprint**
  - Go to OCI Console → Identity → Users → API Keys
  - Copy the fingerprint
  - Add to Jenkins as `oci-key-fingerprint` (Secret Text)

6. **Region**
  - Find in your config file (`region=...`) or top bar in OCI Console
  - Add to Jenkins as `oci-region` (Secret Text)

7. **Auth Token (for Docker login)**
  - Go to OCI Console → Identity → Users → Auth Tokens
  - Generate a new token if needed
  - Add to Jenkins as `oci-auth-token` (Secret Text)

### Step-by-Step Jenkins Credential Configuration

1. Go to **Manage Jenkins → Manage Credentials**
2. Select the appropriate domain (usually "(global)")
3. Click **Add Credentials**
4. For each value above:
  - Select the correct type (Secret Text or Secret File)
  - Enter the ID (e.g., `oci-user-ocid`)
  - Paste the value or upload the file
  - Save

### Example: Adding a Secret Text Credential

1. Click **Add Credentials**
2. Select **Secret Text**
3. Enter the ID (e.g., `oci-user-ocid`)
4. Paste the OCID value
5. Save

### Example: Adding a Secret File Credential

1. Click **Add Credentials**
2. Select **Secret File**
3. Enter the ID (e.g., `oci-key-file`)
4. Upload your private key file
5. Save

---
To securely automate OCI CLI commands in Jenkins, store sensitive values (OCIDs, keys, tokens) as Jenkins credentials and inject them as environment variables during your pipeline run.

### 1. Create Jenkins Credentials

In Jenkins, go to **Manage Jenkins → Manage Credentials** and add the following credentials:

- **oci-compartment-ocid** (Secret Text): Your compartment OCID
- **oci-tenancy-ocid** (Secret Text): Your tenancy OCID
- **oci-user-ocid** (Secret Text): Your user OCID
- **oci-key-file** (Secret File): Your API private key file (upload as a file credential)
- **oci-key-fingerprint** (Secret Text): Your public key fingerprint
- **oci-region** (Secret Text): Your OCI region
- **oci-auth-token** (Secret Text): OCIR auth token (for Docker login)

You can add more credentials as needed for your workflow.

### 2. Inject Credentials in Jenkins Pipeline

Use the `environment` block to inject credentials as environment variables:

```groovy
pipeline {
  agent any
  environment {
    OCI_COMPARTMENT_OCID = credentials('oci-compartment-ocid')
    OCI_TENANCY_OCID = credentials('oci-tenancy-ocid')
    OCI_USER_OCID = credentials('oci-user-ocid')
    OCI_KEY_FILE = credentials('oci-key-file')
    OCI_KEY_FINGERPRINT = credentials('oci-key-fingerprint')
    OCI_REGION = credentials('oci-region')
    OCIR_AUTH_TOKEN = credentials('oci-auth-token')
  }
  stages {
    stage('OCI CLI Example') {
      steps {
        sh '''
          ./ociw.sh os bucket list
          ./ociw.sh compute instance list
        '''
      }
    }
    stage('Docker Login to OCIR') {
      steps {
        sh '''
          docker login $OCI_REGION.ocir.io -u "$OCI_TENANCY_OCID/$OCI_USER_OCID" -p "$OCIR_AUTH_TOKEN"
        '''
      }
    }
  }
}
```

### 3. Notes

- Jenkins will inject credentials only for the build duration, keeping them secure.
- The wrapper script (`ociw.sh`) will use the injected environment variables.
- For file credentials (like the API key), Jenkins will provide the file path in the variable (e.g., `$OCI_KEY_FILE`).
- Never hardcode secrets in your pipeline or repository.

---
To avoid specifying `--compartment-id` (or other OCIDs) every time, use a shell wrapper and environment variables. This is ideal for local use and CI/CD pipelines.

### 1. Create a `.env` file (never commit to git):

```bash
export OCI_COMPARTMENT_OCID=ocid1.compartment.oc1..xxxx
export OCI_TENANCY_OCID=ocid1.tenancy.oc1..xxxx
# ...other variables as needed
```

### 2. Add a wrapper script `ociw.sh` in your project root:

```bash
#!/bin/bash
# Wrapper for OCI CLI to inject default compartment OCID

if [ -z "$OCI_COMPARTMENT_OCID" ]; then
  echo "Error: OCI_COMPARTMENT_OCID not set. Source your .env file first."
  exit 1
fi

# Usage: ./ociw.sh <oci-subcommand> [additional args]
oci "$@" --compartment-id "$OCI_COMPARTMENT_OCID"
```

Make it executable:

```bash
chmod +x ociw.sh
```

### 3. Usage example:

```bash
source .env
./ociw.sh os bucket list
./ociw.sh compute instance list
```

This script automatically injects your compartment OCID, so you never need to specify it manually. You can extend the script to inject other parameters (tenancy, user, etc.) as needed.

For Jenkins or CI/CD, source `.env` at the start of your pipeline and use this wrapper for all OCI CLI calls.

---

### Using OCI CLI Config vs Environment Variables

The OCI CLI uses your `~/.oci/config` file for authentication and resource access. You do **not** need a separate `.env` file for OCIDs if your config is set up.

**When to use environment variables:**
- For automation scripts or Jenkins pipelines that need to reference OCIDs for resource creation, filtering, or logic.
- Not required for basic CLI authentication or most manual commands.

#### How to Find Your OCIDs
- **User OCID:** Go to OCI Console → Identity → Users → Click your user → Copy OCID.
- **Tenancy OCID:** Go to OCI Console → Administration → Tenancy Details → Copy OCID.
- **Compartment OCID:** Go to OCI Console → Identity → Compartments → Click your compartment → Copy OCID.

You can also list resources with the CLI and copy OCIDs from the output:
```bash
oci iam user list
oci iam compartment list
```

### 1. Install OCI CLI

```bash
python3 -m pip install oci-cli
# Or use the official installer:
curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh | bash
```

### 2. Configure OCI CLI

Run the following command and follow the prompts:

```bash
oci setup config
```

This will create the config file at `~/.oci/config`.


Example config file (use your own values):

```ini
[DEFAULT]
user=ocid1.user.oc1..YOUR_USER_OCID
fingerprint=YOUR_PUBLIC_KEY_FINGERPRINT
tenancy=ocid1.tenancy.oc1..YOUR_TENANCY_OCID
region=YOUR_REGION
key_file=~/.ssh/OCI-API.pem
```


**Security Notes:**
- **Never commit secrets, private keys, or sensitive values to GitHub.**
- The `key_file` should point to your API signing key (generated during setup), and this file must be listed in `.gitignore`.
- Store all secrets and sensitive configuration in environment variables or files like `.env` or `oci-secrets.env` that are listed in `.gitignore`.
- You can add multiple profiles in the config file if needed.
- The CLI will use the `[DEFAULT]` profile unless another is specified.

For more details, see the [OCI CLI documentation](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm).


## Pre-Deployment Checklist & Instructions

- [ ] **OCI account with required permissions**
  - Check: `oci iam user get --user-id <your-user-ocid>`
    - Your user OCID can be found in the OCI Console (Identity → Users) or in your config file under `user=`.
  - List policies: `oci iam policy list --compartment-id $OCI_TENANCY_OCID`
  - Required: Policies for Object Storage, Registry, Compute, Networking, Vault.
  - Jenkins pipeline: Should validate permissions before provisioning.

- [ ] **OCI Object Storage bucket created**
  - Check: `oci os bucket list --compartment-id $OCI_COMPARTMENT_OCID`
  - Create: `oci os bucket create --compartment-id $OCI_COMPARTMENT_OCID --name <bucket-name>`
  - Jenkins pipeline: Automate bucket creation if not found.

- [ ] **OCI Container Registry (OCIR) repository created**
  - Check: `oci artifacts container repository list --compartment-id $OCI_COMPARTMENT_OCID`
  - Create: `oci artifacts container repository create --compartment-id $OCI_COMPARTMENT_OCID --display-name <repo-name>`
  - Jenkins pipeline: Automate repo creation if not found.

- [ ] **Compute resource (VM, Container Instance, or OKE) provisioned**
  - Check: `oci compute instance list --compartment-id $OCI_COMPARTMENT_OCID`
  - Create VM: `oci compute instance launch --compartment-id $OCI_COMPARTMENT_OCID --availability-domain <ad> --shape <shape> --image-id <image-ocid> --subnet-id <subnet-ocid>`
  - Create Container Instance: `oci container-instances container-instance create ...`
  - Jenkins pipeline: Automate compute provisioning if not found.

- [ ] **Networking (VCN, subnets, security lists) configured**
  - Check VCN: `oci network vcn list --compartment-id $OCI_COMPARTMENT_OCID`
  - Create VCN: `oci network vcn create --compartment-id $OCI_COMPARTMENT_OCID --display-name <vcn-name> --cidr-block <cidr>`
  - Check subnets: `oci network subnet list --compartment-id $OCI_COMPARTMENT_OCID`
  - Create subnet: `oci network subnet create ...`
  - Check security lists: `oci network security-list list --compartment-id $OCI_COMPARTMENT_OCID`
  - Jenkins pipeline: Automate networking setup if not found.

- [ ] **IAM policies for Object Storage, Registry, and Compute set**
  - Check: `oci iam policy list --compartment-id $OCI_TENANCY_OCID`
  - Create: `oci iam policy create --compartment-id $OCI_TENANCY_OCID --name <policy-name> --statements '["Allow group <group-name> to manage object-family in compartment <compartment-name>", ...]'`
  - Jenkins pipeline: Automate policy creation if not found.

- [ ] **Database (optional) provisioned and accessible**
  - Check: `oci db autonomous-database list --compartment-id $OCI_COMPARTMENT_OCID`
  - Jenkins pipeline: Automate DB provisioning if required.

- [ ] **Secrets/configuration stored in OCI Vault or environment**
  - Check Vault: `oci vault vault list --compartment-id $OCI_COMPARTMENT_OCID`
  - Create secret: `oci secrets secret create ...`
  - Jenkins pipeline: Automate secret creation and injection.

- [ ] **Jenkins/CI/CD pipeline configured (optional)**
  - Jenkins pipeline: Should orchestrate all above steps using OCI CLI and validate each resource before proceeding.

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
