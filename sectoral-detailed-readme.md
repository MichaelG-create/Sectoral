# Documentation Technique Détaillée - Sectoral

> **Guide complet de setup, architecture et troubleshooting**

## 📋 Table des Matières

1. [Architecture Détaillée](#architecture-détaillée)
2. [Setup Environnement](#setup-environnement)
3. [Configuration AWS](#configuration-aws)
4. [Déploiement Terraform](#déploiement-terraform)
5. [Configuration Airflow](#configuration-airflow)
6. [Modèles dbt](#modèles-dbt)
7. [Scripts Python](#scripts-python)
8. [Monitoring & Alertes](#monitoring--alertes)
9. [Troubleshooting](#troubleshooting)
10. [Bonnes Pratiques](#bonnes-pratiques)

---

## 🏗️ Architecture Détaillée

### Flux de Données

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   APIs Externes │    │   Data Pipeline  │    │   Data Storage  │
├─────────────────┤    ├──────────────────┤    ├─────────────────┤
│ • Yahoo Finance │───▶│ Python Ingestion │───▶│ S3 Raw Zone     │
│ • Alpha Vantage │    │ • Validation     │    │ • JSON/Parquet  │
│ • FRED API      │    │ • Enrichment     │    │ • Partitioning  │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Orchestration │    │  Transformation  │    │  Data Warehouse │
├─────────────────┤    ├──────────────────┤    ├─────────────────┤
│ Apache Airflow  │───▶│ dbt Core         │───▶│ Amazon Redshift │
│ • DAGs          │    │ • Staging        │    │ • Dimensional   │
│ • Scheduling    │    │ • Intermediate   │    │ • Star Schema   │
│ • Monitoring    │    │ • Marts          │    │ • Aggregations  │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

### Composants AWS

| Service | Usage | Configuration |
|---------|-------|---------------|
| **S3** | Data Lake | Buckets : raw/, processed/, logs/ |
| **Redshift** | Data Warehouse | dc2.large cluster (dev), ra3.xlplus (prod) |
| **MWAA** | Airflow Managed | Environment v2.5.1, Small instance |
| **IAM** | Sécurité | Roles : AirflowExecutionRole, dbtRole |
| **VPC** | Réseau | Private subnets pour Redshift |
| **CloudWatch** | Monitoring | Logs + métriques custom |

---

## 🛠️ Setup Environnement

### Prérequis Locaux

```bash
# Python 3.8+
python --version

# AWS CLI v2
aws --version
aws configure

# Terraform
terraform --version

# Git
git --version
```

### Variables d'Environnement

```bash
# .env
export AWS_REGION=eu-west-1
export AWS_PROFILE=sectoral
export PROJECT_NAME=sectoral
export ENVIRONMENT=dev

# API Keys (optionnel pour APIs gratuites)
export ALPHA_VANTAGE_API_KEY=your_key_here
export FRED_API_KEY=your_key_here
```

### Installation Python

```bash
# Virtual environment
python -m venv venv
source venv/bin/activate  # Linux/Mac
# venv\Scripts\activate   # Windows

# Requirements
pip install -r requirements.txt
```

**requirements.txt**
```
# Core
pandas>=1.5.0
numpy>=1.21.0
yfinance>=0.2.0
requests>=2.28.0

# AWS
boto3>=1.26.0
awswrangler>=3.0.0

# dbt
dbt-core>=1.4.0
dbt-redshift>=1.4.0

# Airflow (pour développement local)
apache-airflow>=2.5.0
apache-airflow-providers-amazon>=7.0.0

# Utils
python-dotenv>=0.19.0
pydantic>=1.10.0
great-expectations>=0.15.0  # Data quality
```

---

## ☁️ Configuration AWS

### 1. Création du Profil AWS

```bash
aws configure --profile sectoral
# AWS Access Key ID: AKIA...
# AWS Secret Access Key: ...
# Default region: eu-west-1
# Default output format: json
```

### 2. Permissions IAM Requises

**Policy : SectoralDataEngineer**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:*",
                "redshift:*",
                "mwaa:*",
                "iam:PassRole",
                "logs:*",
                "cloudwatch:*"
            ],
            "Resource": "*"
        }
    ]
}
```

### 3. Validation Setup

```bash
# Test connexion
aws sts get-caller-identity --profile sectoral

# Vérification région
aws configure get region --profile sectoral
```

---

## 🚀 Déploiement Terraform

### Structure Terraform

```
terraform/
├── main.tf              # Configuration principale
├── variables.tf         # Variables d'entrée
├── outputs.tf          # Sorties (endpoints, ARNs)
├── providers.tf        # Providers AWS
├── modules/
│   ├── s3/             # Module S3 buckets
│   ├── redshift/       # Module Redshift cluster
│   ├── mwaa/           # Module Airflow
│   └── iam/            # Module IAM roles
└── environments/
    ├── dev.tfvars      # Variables dev
    └── prod.tfvars     # Variables prod
```

### Configuration Principale

**main.tf**
```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

module "s3" {
  source = "./modules/s3"

  project_name = var.project_name
  environment  = var.environment
}

module "redshift" {
  source = "./modules/redshift"

  project_name    = var.project_name
  environment     = var.environment
  master_password = var.redshift_password
}

module "mwaa" {
  source = "./modules/mwaa"

  project_name = var.project_name
  environment  = var.environment
  s3_bucket    = module.s3.airflow_bucket_name
}
```

### Déploiement

```bash
cd terraform/

# Initialisation
terraform init

# Plan (dry-run)
terraform plan -var-file="environments/dev.tfvars"

# Application
terraform apply -var-file="environments/dev.tfvars"

# Vérification
terraform output
```

### Variables Dev

**environments/dev.tfvars**
```hcl
aws_region = "eu-west-1"
aws_profile = "sectoral"
project_name = "sectoral"
environment = "dev"

# Redshift
redshift_node_type = "dc2.large"
redshift_cluster_type = "single-node"
redshift_password = "ChangeMe123!"

# MWAA
mwaa_environment_class = "mw1.small"
mwaa_max_workers = 2
```

---

## 🔄 Configuration Airflow

### Structure DAGs

```
airflow/
├── dags/
│   ├── daily_market_ingestion.py      # Pipeline quotidien
│   ├── weekly_sector_analysis.py      # Analyse hebdomadaire
│   └── data_quality_checks.py         # Tests qualité
├── plugins/
│   ├── sectoral_operators.py          # Custom operators
│   └── sectoral_hooks.py               # Custom hooks
├── config/
│   ├── connections.json               # Connexions Airflow
│   └── variables.json                 # Variables Airflow
└── requirements.txt                   # Dépendances Python
```

### DAG Principal

**daily_market_ingestion.py**
```python
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.amazon.aws.operators.s3 import S3CreateBucketOperator
from sectoral_operators import SectoralIngestionOperator, SectoralTransformOperator

default_args = {
    'owner': 'data-engineering',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': True,
    'email_on_retry': False,
    'retries': 2,
    'retry_delay': timedelta(minutes=5)
}

dag = DAG(
    'daily_market_ingestion',
    default_args=default_args,
    description='Pipeline quotidien d\'ingestion des données de marché',
    schedule_interval='0 6 * * 1-5',  # 6AM lundi-vendredi
    catchup=False,
    tags=['sectoral', 'daily', 'market-data']
)

# Tâches
ingest_stocks = SectoralIngestionOperator(
    task_id='ingest_stock_data',
    data_sources=['yahoo_finance', 'alpha_vantage'],
    symbols="{{ var.value.stock_symbols }}",
    s3_bucket="{{ var.value.s3_raw_bucket }}",
    dag=dag
)

validate_data = PythonOperator(
    task_id='validate_raw_data',
    python_callable=validate_stock_data,
    dag=dag
)

transform_data = SectoralTransformOperator(
    task_id='run_dbt_transformations',
    dbt_project_dir='/opt/airflow/dbt',
    profiles_dir='/opt/airflow/dbt/profiles',
    dag=dag
)

# Dépendances
ingest_stocks >> validate_data >> transform_data
```

### Variables Airflow

```json
{
  "stock_symbols": [
    "AAPL", "MSFT", "GOOGL", "NVDA",
    "JNJ", "PFE", "UNH", "ABBV",
    "JPM", "BAC", "WFC", "GS",
    "XOM", "CVX", "COP", "SLB",
    "AMZN", "TSLA", "HD", "MCD"
  ],
  "s3_raw_bucket": "sectoral-dev-raw-data",
  "redshift_connection": "redshift_default",
  "notification_email": "admin@sectoral.com"
}
```

---

## 🔧 Modèles dbt

### Structure dbt

```
dbt/
├── dbt_project.yml
├── profiles.yml
├── models/
│   ├── staging/
│   │   ├── _sources.yml
│   │   ├── stg_stock_prices.sql
│   │   └── stg_market_indices.sql
│   ├── intermediate/
│   │   ├── int_daily_returns.sql
│   │   └── int_sector_aggregates.sql
│   └── marts/
│       ├── financial/
│       │   ├── dim_sectors.sql
│       │   ├── fact_daily_performance.sql
│       │   └── fact_sector_correlations.sql
│       └── analytics/
│           ├── sector_performance_summary.sql
│           └── risk_metrics.sql
├── macros/
│   ├── calculate_returns.sql
│   └── financial_metrics.sql
├── tests/
└── docs/
```

### Configuration dbt

**dbt_project.yml**
```yaml
name: 'sectoral'
version: '1.0.0'
config-version: 2

profile: 'sectoral'

model-paths: ["models"]
analysis-paths: ["analyses"]
test-paths: ["tests"]
seed-paths: ["seeds"]
macro-paths: ["macros"]

models:
  sectoral:
    +materialized: table
    staging:
      +materialized: view
      +schema: staging
    intermediate:
      +materialized: ephemeral
    marts:
      +materialized: table
      +schema: marts
```

### Modèle Staging

**models/staging/stg_stock_prices.sql**
```sql
{{ config(materialized='view') }}

with raw_prices as (
    select
        symbol,
        date,
        open_price,
        high_price,
        low_price,
        close_price,
        volume,
        adjusted_close,
        created_at
    from {{ source('raw', 'stock_prices') }}
),

cleaned_prices as (
    select
        symbol,
        date::date as price_date,
        open_price::decimal(10,2) as open_price,
        high_price::decimal(10,2) as high_price,
        low_price::decimal(10,2) as low_price,
        close_price::decimal(10,2) as close_price,
        volume::bigint as volume,
        adjusted_close::decimal(10,2) as adjusted_close,
        created_at::timestamp as ingestion_timestamp
    from raw_prices
    where
        close_price > 0
        and volume > 0
        and date >= '2020-01-01'
)

select * from cleaned_prices
```

### Modèle Mart

**models/marts/financial/fact_daily_performance.sql**
```sql
{{ config(materialized='table') }}

with daily_returns as (
    select
        symbol,
        price_date,
        close_price,
        {{ calculate_daily_return('close_price') }} as daily_return,
        {{ calculate_volatility('close_price', 30) }} as volatility_30d
    from {{ ref('stg_stock_prices') }}
),

sector_mapping as (
    select * from {{ ref('dim_sectors') }}
),

performance_metrics as (
    select
        dr.symbol,
        sm.sector_name,
        dr.price_date,
        dr.close_price,
        dr.daily_return,
        dr.volatility_30d,
        sum(dr.daily_return) over (
            partition by dr.symbol
            order by dr.price_date
            rows unbounded preceding
        ) as cumulative_return
    from daily_returns dr
    left join sector_mapping sm on dr.symbol = sm.symbol
)

select * from performance_metrics
```

### Macro Financière

**macros/calculate_returns.sql**
```sql
{% macro calculate_daily_return(price_column) %}
    ({{ price_column }} - lag({{ price_column }}, 1) over (
        partition by symbol
        order by price_date
    )) / lag({{ price_column }}, 1) over (
        partition by symbol
        order by price_date
    )
{% endmacro %}

{% macro calculate_volatility(price_column, window_days) %}
    stddev(
        ({{ price_column }} - lag({{ price_column }}, 1) over (
            partition by symbol
            order by price_date
        )) / lag({{ price_column }}, 1) over (
            partition by symbol
            order by price_date
        )
    ) over (
        partition by symbol
        order by price_date
        rows {{ window_days - 1 }} preceding
    ) * sqrt(252)
{% endmacro %}
```

---

## 📊 Monitoring & Alertes

### Métriques CloudWatch Custom

```python
import boto3

cloudwatch = boto3.client('cloudwatch')

def publish_data_quality_metrics(success_rate, records_processed):
    cloudwatch.put_metric_data(
        Namespace='Sectoral/DataQuality',
        MetricData=[
            {
                'MetricName': 'IngestionSuccessRate',
                'Value': success_rate,
                'Unit': 'Percent'
            },
            {
                'MetricName': 'RecordsProcessed',
                'Value': records_processed,
                'Unit': 'Count'
            }
        ]
    )
```

### Alertes SNS

```python
def send_alert(message, severity='INFO'):
    sns = boto3.client('sns')
    topic_arn = 'arn:aws:sns:eu-west-1:123456789:SectoralAlerts'

    sns.publish(
        TopicArn=topic_arn,
        Message=message,
        Subject=f'[{severity}] Sectoral Pipeline Alert'
    )
```

---

## 🐛 Troubleshooting

### Problèmes Fréquents

#### 1. Terraform Apply Fail
```bash
# Erreur : "AccessDenied"
# Solution : Vérifier les permissions IAM
aws iam list-attached-user-policies --user-name your-user
```

#### 2. Airflow DAG ne démarre pas
```bash
# Vérifier les logs MWAA
aws logs describe-log-groups --log-group-name-prefix="/aws/mwaa/sectoral"

# Test syntaxe DAG
python -c "from airflow.models import DagBag; d = DagBag()"
```

#### 3. dbt Run Failed
```bash
# Debug dbt
dbt debug --profiles-dir ./profiles

# Test connexion Redshift
dbt run --select stg_stock_prices --profiles-dir ./profiles
```

#### 4. API Rate Limits
```bash
# Yahoo Finance : Pas de limite officielle mais throttling
# Solution : Retry avec backoff exponentiel

# Alpha Vantage : 5 calls/minute, 500/day
# Solution : Gérer dans Airflow avec sensor
```

### Logs Utiles

```bash
# Logs Terraform
terraform plan -var-file="dev.tfvars" 2>&1 | tee terraform.log

# Logs Airflow Local
airflow scheduler --log-file scheduler.log

# Logs dbt
dbt run --log-level debug 2>&1 | tee dbt.log
```

---

## ✅ Bonnes Pratiques

### Sécurité
- ✅ Pas de credentials hardcodés
- ✅ Rotation des clés API
- ✅ Encryption S3 et Redshift
- ✅ VPC et Security Groups restrictifs

### Performance
- ✅ Partitioning S3 par date
- ✅ Compression Parquet
- ✅ Index Redshift sur colonnes fréquentes
- ✅ Parallel processing Airflow

### Qualité de Code
- ✅ Tests dbt (unique, not_null, relationships)
- ✅ Documentation models
- ✅ Version control (Git tags)
- ✅ Code review process

### Monitoring
- ✅ Alertes business (données manquantes > 20%)
- ✅ SLA monitoring (pipeline < 2h)
- ✅ Data freshness checks
- ✅ Cost monitoring AWS

---

## 📚 Ressources Complémentaires

- [AWS MWAA Documentation](https://docs.aws.amazon.com/mwaa/)
- [dbt Documentation](https://docs.getdbt.com/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Apache Airflow Guide](https://airflow.apache.org/docs/)

---

**🔗 Retour au [README Principal](README.md)**
