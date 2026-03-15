# Sectoral – Financial Data Pipeline

Automated, production-grade data pipeline for analyzing sectoral performance of financial markets on GCP (GCS, BigQuery, Cloud Composer) with Airflow orchestration and dbt transformations.

## 1. Project Overview

This project ingests market and macro data from multiple financial APIs, stores it in an GCS-based data lake, transforms it with dbt into a BigQuery warehouse, and exposes curated marts for sector performance, risk and trading signal analysis.

**Main goals**:
- Centralize **sector-level** and **symbol-level** market data.
- Compute advanced metrics (returns, volatility, correlations, VaR, sector rotation signals).
- Provide a reproducible, IaC-driven deployment on GCP (Terraform + Cloud Composer + BigQuery).

For detailed technical documentation, see `sectoral-detailed-readme.md`.

## 2. Architecture

![Sectoral workflow](images/sectoral-workflow.png)

High-level data flow:

- External APIs: Alpha Vantage, Yahoo Finance, FRED (macro).
- Ingestion: Python scripts and Airflow DAGs write raw Parquet to GCS.
- Storage: GCS raw zone.
- Transformations: dbt Core on top of BigQuery (staging → intermediate → marts).
- Data warehouse: Google BigQuery (sector and symbol-level tables).
- Analytics: SQL queries, dashboards, and exports.
- Orchestration: Apache Airflow (local and GCP Cloud Composer).


Core folders:

- `src/sectoral/`: application code (ingestion, transforms, CLI, config, operators).
- `airflow/`: local Airflow setup, DAGs, plugins, config.
- `dbt/`: dbt project (`models/`, `macros/`, `tests/`, `profiles.yml.example`).
- `terraform/`: GCP infrastructure (GCS, BigQuery, Cloud Composer, IAM, environments).
- `scripts/`: deployment, setup and utilities (e.g. `deploy_airflow.sh`, `test_connections.py`).
- `tests/`: unit and integration tests for pipeline components and metrics.
- `images/`: architecture diagrams (e.g. `sectoral-workflow.png`).
- `outputs/`: exported CSVs and analysis outputs (e.g. `sector_aggregates.csv`).

## 3. Features

- **Data ingestion**
  - Daily and weekly DAGs for stocks, sectors and macro indicators.
  - Custom Airflow hooks for Alpha Vantage and Yahoo Finance.
  - Local GCS emulation for development (`docker-compose.yml` + `.localgcs/`).

- **Transformations & metrics**
  - dbt models for staging, intermediate and marts (e.g. sector performance, risk metrics, trading signals).
  - Metrics: daily and cumulative returns, rolling volatility, Sharpe ratio, sector correlations, VaR, drawdowns, rotation indicators.

- **Infrastructure & orchestration**
  - Terraform modules for GCS buckets, BigQuery cluster, Cloud Composer environment, IAM roles.
  - Local Airflow environment via Docker for development and debugging.

- **Quality & monitoring**
  Tests are split into `tests/unit` and `tests/integration`, and dbt tests are defined in `dbt/models` YAML files; run `pytest` and `dbt test` for full coverage.
  - dbt tests (not null, accepted values, relationships) and custom tests.
  - Python tests (unit/integration) for ingestion and transformations.
  - CloudWatch / Airflow logs in GCP; local logs for dev.

## 4. Getting Started

### 4.1 Prerequisites

Local tools:

- Python 3.9+
- Terraform 1.0+
- GCP CLI v2 (`gcp configure`)
- Docker + docker-compose
- Git

GCP resources (for cloud deployment):

- GCP account and IAM user/role with permissions for GCS, BigQuery, Cloud Composer, IAM, CloudWatch.

### 4.2 Local setup

1. Clone repo:
   ```bash
   git clone https://github.com/michaelg-create/sectoral.git
   cd sectoral
   ```

2. Environment:
   ```bash
   cp .env.example .env
   # edit API keys, GCP profile/region, project name, etc.
   ```

3. Python dependencies (uv):
   ```bash
   uv sync
   ```

4. Local Airflow (optional for dev):
   ```bash
   docker-compose up -d
   # Airflow at http://localhost:8080
   ```

5. Run tests:
   ```bash
   pytest
   dbt test --project-dir dbt
   ```

### 4.3 GCP deployment (Terraform)

1. Configure Terraform variables:
   ```bash
   cd terraform
   cp environments/dev.tfvars.example environments/dev.tfvars
   # edit project name, region, BigQuery node type, Cloud Composer config…
   ```

2. Deploy:
   ```bash
   terraform init
   terraform plan  -var-file=environments/dev.tfvars
   terraform apply -var-file=environments/dev.tfvars
   ```

Outputs include GCS bucket names, BigQuery endpoint and Cloud Composer environment details.

## 5. Usage

- **Airflow DAGs** (local or Cloud Composer):
  - Daily marketing/sector ingestion: `daily_market_ingestion` (name as defined in `airflow/dags/`).
  - Weekly sector analysis: `weekly_sector_analysis`.
  - Data quality checks (dbt tests, validation operators).

- **dbt**
  ```bash
  cd dbt
  # configure profiles.yml using profiles.yml.example
  dbt seed
  dbt run
  dbt test
  ```

- **CLI / scripts**
  - `src/sectoral/cli.py` (lightweight CLI entrypoints; see docstring and usage examples).
  - `scripts/utilities/test_connections.py` to validate GCP and BigQuery connectivity.

## 6. Roadmap

### Data warehouse (local)

As a data engineer, I want dbt models for sector metrics so I can query performance and showcase a modern data stack.

- **Goal**: `dbt run` + `dbt test` succeed for staging and marts; local Postgres tables are populated.
- **Scope**:
  - Staging and intermediate models for sector metrics (e.g. `stg_*`, `int_*`).
  - Marts for sector performance and risk (e.g. `mart_*`).

#### SEC-US03-T02 – Intermediate & marts models

> “[SEC-US-03] Create intermediate and marts models (int_sector_aggregates, mart_sector_performance).”

- **Status**: Todo
- **Target date**: 2026-01-22
- **Priority**: P0
- **Acceptance criteria**:
  - `int_sector_aggregates` and `mart_sector_performance` materialize successfully in the local Postgres warehouse.
  - Core metrics (returns, volatility, Sharpe ratio, sector performance) are queryable from these tables.
  - `dbt run` and `dbt test` pass for the relevant staging, intermediate and marts models.

These models sit logically in the dbt flow:

`raw (GCS / Postgres) → staging (stg_*) → intermediate (int_sector_aggregates) → marts (mart_sector_performance) → analytics / dashboards.`
