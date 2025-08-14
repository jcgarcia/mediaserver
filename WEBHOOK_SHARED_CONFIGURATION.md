# Jenkins Webhook Shared Configuration

## Overview

This document describes the shared webhook configuration for triggering Jenkins pipeline jobs from GitHub or other SCM systems.

---

## GitHub Webhook Setup

1. Go to your GitHub repository → Settings → Webhooks
2. Add webhook:
   - Payload URL: `http://<jenkins-server>/github-webhook/`
   - Content type: `application/json`
   - Secret: Use Jenkins credential `WebhookSecret`
   - Events: Push events

3. Save and test webhook

---

## Jenkins Pipeline Trigger
- Jenkins will automatically scan branches and trigger builds on push events
- Production deployments are triggered on `main` and `release/*` branches

---

## Troubleshooting
- Ensure Jenkins server is reachable from GitHub
- Check webhook delivery logs in GitHub
- Verify Jenkins credentials and job configuration
