# Snowflake CI/CD with Azure DevOps

Automated deployment pipeline for Snowflake objects using Azure DevOps, featuring environment promotion, approval gates, and zero-copy cloning.

## Overview

This solution enables teams to manage Snowflake infrastructure as code with:

- **Git-based version control** for all database objects
- **Automated deployments** triggered by code changes
- **Environment isolation** (DEV/PROD) with Jinja templating
- **Approval workflows** for production deployments
- **Zero-copy cloning** for instant environment resets

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              CI/CD WORKFLOW                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   Feature Branch Push ──► Validate ──► Deploy to DEV (automatic)            │
│                                                                             │
│   Merge to Main ─────────► Validate ──► Deploy to PROD (with approval)      │
│                                                                             │
│   Manual Trigger ────────► Validate ──► Reset DEV from PROD (zero-copy)     │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                           SNOWFLAKE ENVIRONMENTS                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   CICD_DEMO_PROD ◄──────── Zero-Copy Clone ──────────► CICD_DEMO_DEV        │
│   (Production)                                          (Development)       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Project Structure

```
├── azure-pipelines.yml          # CI/CD pipeline definition
├── manifest.yml                 # Environment configurations (Jinja variables)
├── definitions/
│   ├── 01_infrastructure.sql    # Database, schemas, warehouse
│   ├── 02_raw_tables.sql        # Source tables (CREATE OR ALTER)
│   ├── 03_analytics.sql         # Dynamic tables
│   ├── 04_serve.sql             # Views for consumption
│   └── 05_access.sql            # Roles and grants
├── scripts/
│   └── render_and_deploy.py     # Jinja rendering + SQL execution
└── setup/
    ├── 01_seed_data.sql         # Sample data for demo
    └── 02_git_integration.sql   # Snowflake Git repository setup
```

## Prerequisites

### Azure DevOps
- Azure DevOps organization and project
- Self-hosted agent (recommended) or network policy allowing Microsoft-hosted agent IPs
- Variable group containing `SNOWFLAKE_PRIVATE_KEY` (base64-encoded)

### Snowflake
- Service user with RSA key pair authentication
- Appropriate privileges (ACCOUNTADMIN or custom role)
- Snow CLI available on the build agent

## Setup Instructions

### 1. Create Service User with Key Pair Auth

```sql
-- Generate RSA key pair locally first:
-- openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out cicd_rsa.p8 -nocrypt

-- Create service user
CREATE USER CICD_SERVICE_USER
    TYPE = SERVICE
    DEFAULT_ROLE = ACCOUNTADMIN
    DEFAULT_WAREHOUSE = COMPUTE_WH;

-- Assign public key (from cicd_rsa.p8.pub)
ALTER USER CICD_SERVICE_USER SET RSA_PUBLIC_KEY = '<your_public_key>';
```

### 2. Configure Azure DevOps Variable Group

In Azure DevOps, go to **Pipelines > Library** and create a variable group named `SNOWFLAKE_CREDENTIALS` with:

| Variable | Value | Secret |
|----------|-------|--------|
| SNOWFLAKE_PRIVATE_KEY | Base64-encoded private key | Yes |
| SNOWFLAKE_ACCOUNT | Your account identifier (e.g., xy12345.us-east-1) | No |
| SNOWFLAKE_USER | Your service user name | No |
| SNOWFLAKE_WAREHOUSE | Warehouse to use for deployments | No |
| SNOWFLAKE_DATABASE | Target database (e.g., CICD_DEMO_PROD) | No |
| SNOWFLAKE_ROLE | Role for deployments (e.g., ACCOUNTADMIN) | No |

To base64-encode your private key:
```bash
cat cicd_rsa.p8 | base64 > cicd_rsa.p8.b64
```

### 3. Create the Pipeline

1. Push this repository to Azure DevOps
2. Go to **Pipelines** > **New Pipeline**
3. Select **Azure Repos Git** and your repository
4. Select **Existing Azure Pipelines YAML file**
5. Choose `/azure-pipelines.yml`
6. Run the pipeline

### 4. Configure Production Approval (Optional)

1. Go to **Pipelines** > **Environments**
2. Create or select the `production` environment
3. Add approval check with required reviewers

## Usage

### Deploy to DEV
Push changes to any feature branch:
```bash
git checkout -b my-feature
# Make changes to definitions/*.sql
git add . && git commit -m "Add new column"
git push origin my-feature
```
Pipeline automatically deploys to DEV.

### Deploy to PROD
Create a pull request and merge to `main`. After approval gate, changes deploy to PROD.

### Reset DEV Environment
Run the pipeline manually and set **Reset DEV from PROD** = `true`. This performs a zero-copy clone of PROD to DEV.

## Environment Configuration

The `manifest.yml` controls environment-specific settings:

```yaml
configurations:
  DEV:
    env: "DEV"
    db_suffix: "_DEV"
    wh_size: "X-SMALL"
  PROD:
    env: "PROD"
    db_suffix: "_PROD"
    wh_size: "SMALL"
```

SQL files use Jinja syntax for templating:
```sql
CREATE DATABASE IF NOT EXISTS CICD_DEMO{{db_suffix}};
CREATE WAREHOUSE IF NOT EXISTS CICD_DEMO_WH_{{env}}
    WAREHOUSE_SIZE = '{{wh_size}}';
```

## Key Features

| Feature | Benefit |
|---------|---------|
| **CREATE OR ALTER** | Declarative schema changes without migrations |
| **Zero-Copy Clone** | Instant DEV reset with no storage overhead |
| **Key Pair Auth** | Secure service user authentication (no MFA prompts) |
| **Path Filters** | Pipeline only triggers on SQL/script changes |
| **Approval Gates** | Required review before production deployment |
| **Self-Hosted Agent** | Bypass network policy IP restrictions |

## Troubleshooting

### Pipeline can't connect to Snowflake
- Verify the base64-encoded private key is correct
- Check that the service user has the public key assigned
- Ensure network policies allow the agent's IP

### MFA Required Error
- Service user must use key pair auth, not password
- Set `TYPE = SERVICE` and remove password from user

### Changes not deploying
- Check path filters - only `definitions/*` and `scripts/*` trigger the pipeline
- Verify the correct branch conditions in stage definitions

## Resources

- [Snowflake Key Pair Authentication](https://docs.snowflake.com/en/user-guide/key-pair-auth)
- [Snowflake CREATE OR ALTER](https://docs.snowflake.com/en/sql-reference/sql/create-table#create-or-alter-table)
- [Azure DevOps Pipelines](https://docs.microsoft.com/en-us/azure/devops/pipelines/)
- [Zero-Copy Cloning](https://docs.snowflake.com/en/user-guide/object-clone)
