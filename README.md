# GCP Serverless API Infrastructure with Terraform

This repository contains the Infrastructure as Code (IaC) to deploy a secure, production-ready serverless API architecture on Google Cloud Platform (GCP) using Terraform.

## 🏗️ Architecture Overview

The project provisions the following infrastructure components:
*   **Networking:** Custom VPC with a Serverless VPC Access Connector for private routing.
*   **Database:** Private Cloud SQL (PostgreSQL) instance accessible only internally.
*   **Secrets:** Google Secret Manager to securely store database credentials.
*   **Compute:** Cloud Run service hosting a containerized API.
*   **Registry:** Artifact Registry for secure Docker image management.

## 📁 Project Structure

```text
gcp-api-terraform/
├── main.tf          # Core infrastructure resources and provider configuration
├── variables.tf     # Input variable definitions
├── outputs.tf       # Infrastructure outputs (URLs, IDs)
├── .gitignore       # Git ignore rules for Terraform
└── README.md        # Project documentation# gcp-api-terraform
