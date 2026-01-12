**Project Overview**

This repo implements an AWS-centric data pipeline for sectoral financial analysis. Main components are Airflow (orchestration), dbt (transformations), Terraform (infra), and Python services under `src/sectoral` that perform ingestion, transforms and exports.

**Quick Orientation**
- **Orchestration**: Airflow DAGs live in [airflow/dags](airflow/dags) (see `daily_market_ingestion.py`).
- **Operators & runtime code**: core runtime lives in `src/sectoral` (not `airflow/plugins`). See [src/sectoral/operators.py](src/sectoral/operators.py) for custom Airflow-compatible operators.
- **Transforms**: dbt models are in [dbt/models](dbt/models).
- **Infra**: Terraform manifests in [terraform](terraform).
- **Local dev**: `docker-compose.yml` spins up Postgres + Airflow for local testing.

**What to change and why**
- Prefer editing `src/sectoral` code for operator logic (Airflow imports reference `sectoral.operators`). Do not assume `airflow/plugins` is the primary source for production operators.
- DAG definitions in [airflow/dags/daily_market_ingestion.py](airflow/dags/daily_market_ingestion.py) import `SectoralIngestionOperator` and `SectoralTransformOperator` from the `sectoral` package — keep template_fields and file paths stable (`/opt/airflow/local_s3`, `config/sectoral.yaml`).

**Developer Workflows (concrete commands)**
- Create virtualenv and install deps: `make setup-env` (or `python -m venv venv && pip install -r requirements.txt`). See [Makefile](Makefile).
- Run tests: `make test` or `pytest tests/ -v`.
- Run local Airflow: `make start-local-dev` (starts `docker-compose up -d` which uses [docker-compose.yml](docker-compose.yml)).
- Run dbt locally: `make dbt-run` from project root (uses `dbt/` directory).
- Terraform: `cd terraform && terraform init && terraform plan` (see `Makefile` targets `tf-init`, `tf-plan`).

**Project-specific conventions**
- Python package entrypoint is `src/sectoral` and CLI script `sectoral_poc.py` uses `sectoral.cli:main` (see `pyproject.toml` scripts).
- I/O paths in Airflow tasks use `/opt/airflow/local_s3` for development (bind-mounted to `./local_s3` in `docker-compose.yml`). Keep that path when writing or testing DAGs/operators.
- Configs are YAML under `config/` (`config/sectoral.yaml`) and are loaded via `SectoralConfig.from_yaml` (see `src/sectoral/config.py`).
- Operators return plain dicts (they rely on Airflow XCom push-by-return). Prefer serializable primitives in returns.

**Integration points & external dependencies**
- External APIs: Alpha Vantage, Yahoo Finance, FRED (dependencies listed in `pyproject.toml`). Credentials live in environment variables / `.env` (see README).
- AWS: S3 buckets and MWAA/Redshift. Deployment expects Terraform-managed resources under `terraform/`.
- Airflow in CI: workflows are under `.github/workflows` — use `make airflow-test` and `airflow dags test` for DAG unit checks.

**Examples & Patterns to Follow**
- Operator pattern: `SectoralIngestionOperator` and `SectoralTransformOperator` in [src/sectoral/operators.py](src/sectoral/operators.py). Follow `template_fields`, `execute()` returning a dict, and path handling via `pathlib.Path`.
- DAG pattern: lightweight DAGs declare config path & directories as templated strings so they are overridable via Airflow Variables/Connections. See [airflow/dags/daily_market_ingestion.py](airflow/dags/daily_market_ingestion.py).
- Tests: unit tests live in `tests/unit` and mirror operator behaviors — inspect `tests/test_operators.py` for examples of expected operator behavior.

**What NOT to do**
- Don’t hardcode production AWS identifiers in code. Use `terraform` outputs or Airflow Variables for environment-specific values.
- Don’t change DAG IDs or template field names without updating tests and MWAA deployment sync.

**Where to look first when debugging**
- Airflow logs: `airflow/logs/` (local) or CloudWatch (prod). Use `Makefile` target `view-logs` for AWS logs.
- Local storage: `local_s3/` holds raw CSVs when running locally via docker-compose.
- DBT failures: check `dbt/target` logs and `dbt` run output.

If anything here is unclear or you want more depth (examples for editing DAGs, writing new operators, or a checklist for MWAA deployment), tell me which area to expand.
