# Application gateway mTLS POC -  Terraform Infrastructure

This project provisions a sample Azure environment for a proof-of-concept of Application gateway mTLS POC using Terraform. It automates the creation of networking, security, compute, and load balancing resources, including Application Gateway with SSL, VNet peering, a Windows web server, and a public load balancer.

---

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) installed on your machine.
- An Azure subscription with permissions to create resources.
- Azure CLI or Service Principal credentials for authentication.
- SSL certificate files (PFX and CER) for Application Gateway.

---

## Project Structure

- `main.tf`: Main configuration for all Azure resources.
- `variables.tf`: Input variables for the deployment.
- `outputs.tf`: Outputs for key resource IDs and properties.
- `README.md`: Project documentation.

---

## Resources Created

- **Resource Group**
- **Virtual Networks**: External (routable) and internal, each with subnets.
- **Subnets**: For Application Gateway, workloads, and internal apps.
- **VNet Peering**: Bidirectional peering between VNets.
- **Application Gateway**: With SSL termination, rewrite rules, and client certificate validation.
- **Windows Web Server**: Deployed in the internal VNet.
- **Public Load Balancer**: In the workload subnet.
- **Network Security Groups**: With rules for HTTP and RDP.
- **Public IPs**: For Application Gateway and Load Balancer.

---

## Getting Started

1. **Clone the repository** to your local machine.
2. **Navigate to the project directory:**
   ```sh
   cd terraform
   ```
3. **Update variables** in `variables.tf` and certificate paths/passwords in `main.tf` as needed.
4. **Initialize Terraform:**
   ```sh
   terraform init
   ```
5. **Review the planned actions:**
   ```sh
   terraform plan
   ```
6. **Apply the configuration:**
   ```sh
   terraform apply
   ```

---

## Outputs

After applying, Terraform will output resource IDs and addresses for the created VNets, Application Gateway, Load Balancer, and other key resources.

---

## Cleanup

To remove all created resources, run:
```sh
terraform destroy
```

---

## Notes

- Review and update certificate paths and passwords before deployment.
- NSG rules are for demonstration; restrict as needed for production.
- This configuration is a starting point for enterprise Azure networking and application deployment. Customize it to meet your specific requirements and security standards.