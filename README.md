# GCP Serverless API Infrastructure with Terraform

This repository contains the Infrastructure as Code (IaC) to provision a secure, production-ready serverless API architecture on Google Cloud Platform (GCP) using Terraform.

## 🏗️ Architecture Overview

The project provisions and interconnects the following native GCP resources:
* **Networking (Custom VPC):** A brand new, isolated VPC network with a regional subnetwork and a **Serverless VPC Access Connector** for secure, private outbound routing.
* **Database (Cloud SQL PostgreSQL):** A private database instance with public IP completely disabled (`ipv4_enabled = false`), communicating exclusively via VPC Peering.
* **Security (Secret Manager & Random):** Automatic generation of a high-entropy database password, stored directly into an encrypted cloud vault without hardcoded values.
* **Artifacts (Artifact Registry):** A private regional Docker repository to host your application's container images.
* **Compute (Cloud Run v2):** A serverless engine hosting the public API, configured following the principle of least privilege using a dedicated IAM Service Account, secure environment variables, and private database network mapping.

## 📁 Project Structure

```text
gcp-api-terraform/
├── main.tf          # Resource definitions, cloud APIs, and provider configs
├── variables.tf     # Input variables (with hardcoded default Project ID)
├── outputs.tf       # Extracted infrastructure data (URLs, private IPs)
└── .gitignore       # Git ignore rules for local state and sensitive files
```

## 🛠️ Prerequisites

Before executing the code, ensure your local machine has:

    Terraform CLI (Minimum version: >= 1.5.0)

    Google Cloud SDK (gcloud CLI)

## 🚀 Step-by-Step Replication Guide
### Step 1: Authenticate with Google Cloud

Open your terminal in the root directory of the project. Run the following commands to log into your Google account and generate the local Application Default Credentials (ADC) that Terraform relies on:

```bash
gcloud auth login
gcloud auth application-default login
```

### Step 2: Create the Remote State Bucket

Terraform requires a Cloud Storage bucket to host its runtime history file (`terraform.tfstate`). Create this bucket via the Google CLI before initializing the code:

```bash
gcloud storage buckets create gs://gcp-api-tfstate-bucket --location=us-central1
```

### Step 3: Initialize the Project

Now that the bucket exists and your main.tf has the gcs backend block configured, initialize the working directory to download the required plugins (google and random):

```bash
terraform init
```

### Step 4: Plan the Infrastructure

Generate and review the execution plan. This acts as a safety dry-run to ensure all resources mapped by the code match your deployment expectations (look for the + sign for creations):

```bash
terraform plan
```

### Step 5: Deploy to Production

Apply the configuration to your GCP project. The process will provision networks, credentials, databases, and compute. When prompted, type yes to confirm:

```bash
terraform apply
```

Note: If you encounter a transient Google API IAM consistency error (Error code 7) during the initial Cloud Run service setup, simply run terraform apply one more time. This happens because GCP takes a few seconds to propagate newly created service account permissions across its global infrastructure.

## 🧪 Validation and Testing

Once the deployment finishes successfully, Terraform will output the public endpoints. You can query the live API URL at any time by running:

```bash
terraform output api_url
```

To test the public endpoint and verify that the default Google bootstrap container is up and running successfully (HTTP/2 200), execute a curl request:

```bash
curl -I $(terraform output -raw api_url)
```

## 🧼 Resource Cleanup (Destruction)

To avoid unwanted charges on your billing account from active resources (especially the Cloud SQL engine), you can teardown the entire infrastructure provisioned by this repository with a single command:

```bash
terraform destroy
```

Confirm the operation by typing yes when prompted.