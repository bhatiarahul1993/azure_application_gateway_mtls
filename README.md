# azure_azure_application_gateway_mtls

This repository demonstrates how to configure Azure Application Gateway with mutual TLS (mTLS) authentication using Terraform and a sample Node.js application which prints X-headers in the web page.

## Repository Structure

- `headers_app/` - Sample Node.js application for testing Application Gateway.
  - `server.js` - Main server file.
  - `package.json` - Node.js dependencies and scripts.
  - `public/index.html` - Simple HTML page for testing.

- `terraform/` - Terraform scripts and certificate files for Azure resources.
  - `main.tf` - Main Terraform configuration for Application Gateway and related resources.
  - `variables.tf` - Input variables for Terraform.
  - `outputs.tf` - Output values from Terraform deployment.
  - `certificate.cer`, `certificate.pfx`, `exported_certificate.cer` - Example certificate files for mTLS.
  - `terraform.tfstate`, `terraform.tfstate.backup` - Terraform state files (auto-generated).
  - `README.md` - Documentation for the Terraform setup.

## Usage

1. Deploy Azure resources using the Terraform files in the `terraform/` directory.
2. Run the Node.js app in `headers_app/` to test mTLS authentication through the Application Gateway.

## Prerequisites
- Azure account
- Terraform
- Node.js and npm

## License
This repository is for demonstration purposes only. Update certificates and secrets before using.