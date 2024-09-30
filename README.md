# Restaurant Recommender System

## Overview

This project is a cloud-native application that provides restaurant recommendations based on user-specified criteria such as cuisine style, vegetarian options, and current opening hours. The system is built using AWS services and follows Infrastructure as Code (IaC) principles using Terraform for resource provisioning. It includes a CI/CD pipeline for automatic deployment of code changes, including updates to the list of restaurants.

## Features

- **API Endpoint**: Query the system with specific parameters to receive a restaurant recommendation.
- **Backend Storage**: Stores restaurant data and request history securely in Amazon DynamoDB.
- **Infrastructure as Code**: Uses Terraform to provision and manage AWS resources.
- **CI/CD Pipeline**: Automates deployment of code changes and data updates using GitHub Actions.
- **Security**: Implements best practices to ensure data confidentiality and secure resource access.

## Prerequisites

Before setting up the project, ensure you have the following:

- **AWS Account**: Access to AWS to create and manage resources.
- **AWS CLI**: Installed and configured on your local machine.
- **Terraform**: Installed on your local machine.
- **Python 3.8**: Required for the Lambda function code and scripts.
- **Git**: For cloning the repository and version control.
- **GitHub Account**: For accessing the repository and configuring secrets.

## Setup Instructions

### 1. Clone the Repository

Clone the repository to your local machine:

```bash
git clone https://github.com/garybrownoct/varonis-restaurants-api.git
cd varonis-restaurants-api
```

### 2. Configure AWS Credentials

Ensure your AWS CLI is configured with credentials that have the necessary permissions:

```bash
aws configure
```

Provide your AWS Access Key ID, Secret Access Key, default region (e.g., `us-east-1`), and default output format (`json`).

### 3. Set Up Terraform Locally

Install Terraform if you haven't already. Follow the [Terraform installation guide](https://learn.hashicorp.com/tutorials/terraform/install-cli).

### 4. Provision AWS Resources with Terraform

Navigate to the `terraform` directory:

```bash
cd terraform
```

Initialize Terraform:

```bash
terraform init
```

Plan the infrastructure deployment:

```bash
terraform plan
```

Review the plan output to understand the resources that will be created.

Apply the Terraform plan:

```bash
terraform apply
```

Confirm the apply by typing `yes` when prompted.

**Note**: This step provisions the following AWS resources:

- DynamoDB tables: `restaurants` and `requests_history`
- IAM role and policy for the Lambda function
- Lambda function (code deployment handled separately)
- API Gateway with an endpoint

### 5. Configure the CI/CD Pipeline

The CI/CD pipeline is set up using GitHub Actions.

Add your AWS credentials as secrets in your GitHub repository:

- Go to your repository on GitHub.
- Click on **Settings** > **Secrets and variables** > **Actions**.
- Click **New repository secret**.
- Add the following secrets:

  - **Name**: `AWS_ACCESS_KEY_ID`, **Value**: Your AWS Access Key ID
  - **Name**: `AWS_SECRET_ACCESS_KEY`, **Value**: Your AWS Secret Access Key

## Usage

### API Endpoint

After deploying the infrastructure, you can find the API endpoint URL in the AWS API Gateway console or from the Terraform output if configured.

Example endpoint format:

```
https://<api-id>.execute-api.us-east-1.amazonaws.com/prod/restaurants
```

### Making a Request

You can query the API using HTTP GET requests with query parameters:

- **style**: Cuisine style (e.g., `Italian`, `French`, `Korean`, `Japanese`)
- **vegetarian**: `true` or `false` (case-insensitive)
- **isOpenNow**: `true` or `false` (case-insensitive)

#### Example Request

Request a vegetarian Italian restaurant that is open now:

```bash
curl "https://<api-id>.execute-api.us-east-1.amazonaws.com/prod/restaurants?style=Italian&vegetarian=true&isOpenNow=true"
```

### Example Responses

**Successful Response:**

```json
{
  "restaurantRecommendation": {
    "name": "Vegetarian Pasta Place",
    "style": "Italian",
    "address": "123 Green Street",
    "openHour": "11:00",
    "closeHour": "22:00",
    "vegetarian": true
  }
}
```

## Updating Restaurants Data

To add or update restaurants:

1. Modify the `restaurants.json` file in the `lambda` directory to include new or updated restaurant data.
2. Commit and push your changes to the `main` branch:

   ```bash
   git add lambda/restaurants.json
   git commit -m "Add new restaurant"
   git push origin main
   ```

3. The CI/CD pipeline will automatically deploy the changes:

   - Update the Lambda function code (if necessary).
   - Run `load_restaurants.py` to update the DynamoDB table.
