# Snowflake CI/CD with Azure DevOps

Automated deployment pipeline for Snowflake objects using Azure DevOps and `snow git execute`.

## Overview

This solution uses Snowflake's native Git integration to execute SQL directly from a connected repository:

- **Git-based version control** for all database objects
- **Automated deployments** triggered by code changes
- **Jinja templating** for environment-specific configs (DEV/PROD)
- **Approval workflows** for production deployments
- **Zero-copy cloning** for instant environment resets

## How It Works

```
Azure DevOps (source of truth)
        |
        | git push
        v
+------------------+
| Azure DevOps     |
| Pipeline Trigger |
+------------------+
        |
        | snow git fetch
        v
+------------------+
| Snowflake Git    |
| Repository Clone |
+------------------+
        |
        | snow git execute
        v
+------------------+
| SQL Executed     |
| with Jinja vars  |
+------------------+
```

1. Developer pushes to Azure DevOps (or Snowflake Workspaces)
2. Pipeline triggers and runs `snow git fetch` to sync Snowflake's clone
3. `snow git execute` runs SQL files with environment-specific Jinja variables

## Project Structure

```
├── azure-pipelines.yml          # CI/CD pipeline definition
├── definitions/
│   ├── 01_infrastructure.sql    # Database, schemas, warehouse
│   ├── 02_raw_tables.sql        # Source tables (CREATE OR ALTER)
│   ├── 03_analytics.sql         # Dynamic tables
│   ├── 04_serve.sql             # Views for consumption
│   └── 05_access.sql            # Roles and grants
└── setup/
    ├── 01_seed_data.sql         # Sample data for demo
    └── 02_git_integration.sql   # Snowflake Git repository setup
```

## Prerequisites

### Azure DevOps
- Azure DevOps organization and project
- Self-hosted agent (recommended) or network policy allowing Microsoft-hosted agent IPs
- Variable group `SNOWFLAKE_CREDENTIALS` with connection details

### Snowflake
- Service user with RSA key pair authentication
- Git repository connected to Snowflake (see `setup/02_git_integration.sql`)
- Appropriate privileges (ACCOUNTADMIN or custom role)

## Setup Instructions

### 1. Create Service User with Key Pair Auth

```sql
-- Generate RSA key pair locally:
-- openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out cicd_rsa.p8 -nocrypt

CREATE USER CICD_SERVICE_USER
    TYPE = SERVICE
    DEFAULT_ROLE = ACCOUNTADMIN
    DEFAULT_WAREHOUSE = COMPUTE_WH;

ALTER USER CICD_SERVICE_USER SET RSA_PUBLIC_KEY = '<your_public_key>';
```

### 2. Connect Git Repository to Snowflake

Run the SQL in `setup/02_git_integration.sql` to create:
- Secret for Azure DevOps PAT
- API integration for Git HTTPS
- Git repository object in Snowflake

### 3. Configure Azure DevOps Variable Group

Create a variable group named `SNOWFLAKE_CREDENTIALS` with:

| Variable | Value | Secret |
|----------|-------|--------|
| SNOWFLAKE_PRIVATE_KEY | Base64-encoded private key | Yes |
| SNOWFLAKE_ACCOUNT | Your account identifier | No |
| SNOWFLAKE_USER | Service user name | No |
| SNOWFLAKE_WAREHOUSE | Warehouse for deployments | No |
| SNOWFLAKE_DATABASE | Target database | No |
| SNOWFLAKE_ROLE | Role for deployments | No |

Base64-encode your private key:
```bash
cat cicd_rsa.p8 | base64 > cicd_rsa.p8.b64
```

### 4. Create the Pipeline

1. Push this repository to Azure DevOps
2. Go to **Pipelines** > **New Pipeline**
3. Select **Azure Repos Git** and your repository
4. Select **Existing Azure Pipelines YAML file**
5. Choose `/azure-pipelines.yml`
6. Run the pipeline

### 5. Configure Production Approval (Optional)

1. Go to **Pipelines** > **Environments**
2. Create or select the `production` environment
3. Add approval check with required reviewers

## Usage

### Deploy to DEV
Push changes to any feature branch:
```bash
git checkout -b my-feature
# Edit files in definitions/
git add . && git commit -m "Add new column"
git push origin my-feature
```
Pipeline automatically:
1. Syncs Snowflake's Git clone with `snow git fetch`
2. Executes SQL with DEV variables: `env='DEV'`, `db_suffix='_DEV'`, `wh_size='X-SMALL'`

### Deploy to PROD
Merge to `main` branch. After approval gate, pipeline executes with PROD variables.

### Reset DEV Environment
Run pipeline manually with **Reset DEV from PROD** = `true`. This:
1. Zero-copy clones PROD to DEV
2. Re-executes SQL with DEV variables

## Jinja Templating

SQL files use Jinja syntax. Variables are passed via `snow git execute -D`:

```sql
CREATE DATABASE IF NOT EXISTS CICD_DEMO{{db_suffix}};

CREATE WAREHOUSE IF NOT EXISTS CICD_DEMO_WH_{{env}}
    WAREHOUSE_SIZE = '{{wh_size}}';
```

Pipeline passes environment-specific values:
- **DEV**: `-D "env='DEV'" -D "db_suffix='_DEV'" -D "wh_size='X-SMALL'"`
- **PROD**: `-D "env='PROD'" -D "db_suffix='_PROD'" -D "wh_size='SMALL'"`

## Key Features

| Feature | Benefit |
|---------|---------|
| **snow git execute** | No Python scripts - SQL runs directly in Snowflake |
| **CREATE OR ALTER** | Declarative schema changes without migrations |
| **Zero-Copy Clone** | Instant DEV reset with no storage overhead |
| **Key Pair Auth** | Secure service user authentication (no MFA) |
| **Path Filters** | Pipeline only triggers on SQL definition changes |
| **Approval Gates** | Required review before production deployment |

## Troubleshooting

### Pipeline can't connect to Snowflake
- Verify base64-encoded private key is correct (no trailing whitespace)
- Check service user has public key assigned
- Ensure network policies allow agent's IP

### snow git fetch fails
- Verify Git repository exists: `SHOW GIT REPOSITORIES`
- Check API integration is enabled
- Ensure PAT token hasn't expired

### SQL execution fails
- Check Jinja variable syntax: `{{variable}}` not `{{ variable }}`
- Verify all variables are passed via `-D` flags
- Check for CREATE OR ALTER limitations (new columns must be at end)

## Resources

- [Snowflake DevOps Guide](https://docs.snowflake.com/en/developer-guide/builders/devops)
- [snow git execute](https://docs.snowflake.com/en/developer-guide/snowflake-cli/git/execute-sql)
- [Key Pair Authentication](https://docs.snowflake.com/en/user-guide/key-pair-auth)
- [Zero-Copy Cloning](https://docs.snowflake.com/en/user-guide/object-clone)
