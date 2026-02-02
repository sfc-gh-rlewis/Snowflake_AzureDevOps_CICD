# Snowflake CI/CD with Azure DevOps Demo

This demo shows how to implement automated CI/CD for Snowflake using:
- **Jinja Templating** - Environment-specific configurations (DEV/PROD)
- **Azure DevOps Git Integration** - Native Snowflake connection to Azure repos
- **Azure Pipelines** - Automated deployment on PR merge
- **Snow CLI** - Execute SQL from pipeline
- **Zero Copy Cloning** - Instant test data in DEV from PROD

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         DEVELOPMENT WORKFLOW                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   Snowflake Workspaces ──────► Azure DevOps Repo ──────► Pull Request   │
│   (Edit SQL files)             (Version control)        (Code review)   │
│                                                                         │
├─────────────────────────────────────────────────────────────────────────┤
│                           CI/CD PIPELINE                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   Validate (analyze) ──────► Plan (preview) ──────► Deploy (on merge)   │
│                                                                         │
├─────────────────────────────────────────────────────────────────────────┤
│                          DATA ENVIRONMENTS                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   CICD_DEMO_PROD ◄──────────── Zero Copy Clone ──────────► CICD_DEMO_DEV│
│   (Production data)                                        (Test data)  │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

## Project Structure

```
azure_devops_cicd/
├── manifest.yml                 # Environment configurations (Jinja variables)
├── definitions/
│   ├── 01_infrastructure.sql   # Database, schemas, warehouse
│   ├── 02_raw_tables.sql       # Source tables
│   ├── 03_analytics.sql        # Dynamic tables
│   ├── 04_serve.sql            # Views for consumption
│   └── 05_access.sql           # Roles and grants
├── scripts/
│   └── render_and_deploy.py    # Jinja rendering + SQL execution
├── azure-pipelines.yml          # CI/CD pipeline definition
├── setup/
│   ├── 01_seed_data.sql        # Sample data for demo
│   └── 02_git_integration.sql  # Git repository setup
└── README.md
```

## Prerequisites

### Azure DevOps
1. Azure DevOps organization and project
2. Personal Access Token (PAT) with:
   - Code: Read & Write
   - Build: Read & Execute

### Snowflake
1. ACCOUNTADMIN role (or equivalent privileges)
2. Snow CLI installed (for local testing)

## Setup Instructions

### Step 1: Clone Repository Locally

```bash
git clone https://reidlewis@dev.azure.com/reidlewis/Snowflake_DevOps_Demo/_git/Snowflake_DevOps_Demo
cd Snowflake_DevOps_Demo
```

### Step 2: Copy Demo Files

Copy all files from this directory to your cloned repo.

### Step 3: Configure Azure Pipeline Variables

In Azure DevOps, go to Pipelines > Library and create a variable group with:

| Variable | Value | Secret |
|----------|-------|--------|
| SNOWFLAKE_PASSWORD | (service user password) | Yes |

### Step 4: Push to Azure DevOps

```bash
git add .
git commit -m "Initial DCM project setup"
git push origin main
```

### Step 5: Create Pipeline

1. Go to Pipelines in Azure DevOps
2. Create new pipeline
3. Select Azure Repos Git
4. Select your repository
5. Select "Existing Azure Pipelines YAML file"
6. Select `/azure-pipelines.yml`
7. Run the pipeline

## Demo Workflow

### 1. Show Current State (Pain Point)

Explain how the customer currently:
- Manually creates objects in prod and non-prod
- Copies scripts from Azure DevOps
- Pastes into Snowflake to execute

### 2. Show Zero Copy Clone

```sql
-- Instantly create DEV with all PROD data
CREATE DATABASE CICD_DEMO_DEV CLONE CICD_DEMO_PROD;

-- Verify data is available (no copy time!)
SELECT COUNT(*) FROM CICD_DEMO_DEV.RAW.ORDERS;
```

### 3. Make a Change in Workspaces

1. Open Snowflake Workspaces
2. Connect to the Git repository
3. Edit `definitions/02_raw_tables.sql`
4. Add a new column to ORDERS table:

```sql
-- Add this column to ORDERS table
PRIORITY VARCHAR(20) DEFAULT 'NORMAL',
```

5. Commit and push to a feature branch

### 4. Create Pull Request

1. In Azure DevOps, create PR from feature branch to main
2. Pipeline automatically runs Validate and Plan stages
3. Review the plan output - shows exactly what will change

### 5. Merge and Auto-Deploy

1. Approve and merge the PR
2. Pipeline automatically deploys to PROD
3. Show the new column in CICD_DEMO_PROD.RAW.ORDERS

### 6. Verify Deployment

```sql
-- Query the updated table
DESCRIBE TABLE CICD_DEMO_PROD.RAW.ORDERS;

-- Check the data
SELECT * FROM CICD_DEMO_PROD.SERVE.V_CUSTOMER_ORDERS;
```

## Key Demo Points

1. **Version Control**: All Snowflake objects defined as code in Git
2. **Environment Parity**: Same definitions deploy to DEV and PROD via Jinja
3. **Automated Validation**: DCM analyze catches errors before deployment
4. **Safe Deployments**: Plan shows exactly what will change
5. **Zero Copy Cloning**: Instant test data without storage costs
6. **Audit Trail**: Git history + DCM deployment history
7. **Workspaces Integration**: Developers stay in Snowflake UI

## Jinja Templating Example

The `manifest.yml` defines environment-specific variables:

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

In definitions, use `{{variable}}` syntax:

```sql
DEFINE DATABASE CICD_DEMO{{db_suffix}};

DEFINE WAREHOUSE CICD_DEMO_WH_{{env}}
WITH WAREHOUSE_SIZE = '{{wh_size}}';
```

**Result for DEV**: `CICD_DEMO_DEV`, `CICD_DEMO_WH_DEV` (X-SMALL)
**Result for PROD**: `CICD_DEMO_PROD`, `CICD_DEMO_WH_PROD` (SMALL)

## Troubleshooting

### Pipeline Fails at Analyze

Check that:
- DCM project exists in Snowflake
- Service user has correct permissions
- Connection credentials are valid

### Git Integration Issues

Verify:
- PAT token has not expired
- API integration is enabled
- Repository URL is correct

## Resources

- [Snowflake DCM Documentation](https://docs.snowflake.com/en/developer-guide/snowflake-cli/dcm/overview)
- [Snowflake Git Integration](https://docs.snowflake.com/en/developer-guide/git/git-overview)
- [Azure DevOps Pipelines](https://docs.microsoft.com/en-us/azure/devops/pipelines/)
