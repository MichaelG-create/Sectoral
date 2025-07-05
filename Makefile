# Financial Data Pipeline Makefile

# Variables
PROJECT_NAME := financial-data-pipeline
PYTHON_VERSION := 3.9
VENV_NAME := venv
TERRAFORM_DIR := terraform
DBT_DIR := dbt
AIRFLOW_DIR := airflow

# Default target
.PHONY: help
help:
	@echo "Financial Data Pipeline - Available Commands:"
	@echo ""
	@echo "Setup Commands:"
	@echo "  setup-env         - Create virtual environment and install dependencies"
	@echo "  install-deps      - Install Python dependencies"
	@echo "  setup-pre-commit  - Setup pre-commit hooks"
	@echo ""
	@echo "Development Commands:"
	@echo "  format            - Format code with black and isort"
	@echo "  lint              - Run linting with flake8"
	@echo "  test              - Run pytest"
	@echo "  test-coverage     - Run tests with coverage"
	@echo ""
	@echo "Infrastructure Commands:"
	@echo "  tf-init           - Initialize Terraform"
	@echo "  tf-plan           - Plan Terraform deployment"
	@echo "  tf-apply          - Apply Terraform changes"
	@echo "  tf-destroy        - Destroy Terraform infrastructure"
	@echo ""
	@echo "Data Pipeline Commands:"
	@echo "  dbt-deps          - Install dbt dependencies"
	@echo "  dbt-run           - Run dbt models"
	@echo "  dbt-test          - Run dbt tests"
	@echo "  dbt-docs          - Generate and serve dbt documentation"
	@echo ""
	@echo "Airflow Commands:"
	@echo "  airflow-init      - Initialize Airflow database"
	@echo "  airflow-start     - Start Airflow webserver and scheduler"
	@echo "  airflow-test      - Test Airflow DAGs"
	@echo ""
	@echo "Deployment Commands:"
	@echo "  deploy-infra      - Deploy infrastructure"
	@echo "  deploy-pipeline   - Deploy data pipeline"
	@echo "  deploy-all        - Deploy everything"
	@echo ""
	@echo "Cleanup Commands:"
	@echo "  clean             - Clean temporary files"
	@echo "  clean-all         - Clean everything including virtual environment"

# Setup Commands
.PHONY: setup-env
setup-env:
	python3 -m venv $(VENV_NAME)
	./$(VENV_NAME)/bin/pip install --upgrade pip
	./$(VENV_NAME)/bin/pip install -r requirements.txt
	@echo "Virtual environment created and dependencies installed"

.PHONY: install-deps
install-deps:
	pip install --upgrade pip
	pip install -r requirements.txt

.PHONY: setup-pre-commit
setup-pre-commit:
	pre-commit install
	pre-commit autoupdate

# Development Commands
.PHONY: format
format:
	black python-scripts/ airflow/ tests/
	isort python-scripts/ airflow/ tests/

.PHONY: lint
lint:
	flake8 python-scripts/ airflow/ tests/
	mypy python-scripts/ airflow/

.PHONY: test
test:
	pytest tests/ -v

.PHONY: test-coverage
test-coverage:
	pytest tests/ --cov=python-scripts --cov=airflow --cov-report=html --cov-report=term

# Infrastructure Commands
.PHONY: tf-init
tf-init:
	cd $(TERRAFORM_DIR) && terraform init

.PHONY: tf-plan
tf-plan:
	cd $(TERRAFORM_DIR) && terraform plan

.PHONY: tf-apply
tf-apply:
	cd $(TERRAFORM_DIR) && terraform apply

.PHONY: tf-destroy
tf-destroy:
	cd $(TERRAFORM_DIR) && terraform destroy

.PHONY: tf-validate
tf-validate:
	cd $(TERRAFORM_DIR) && terraform validate

.PHONY: tf-fmt
tf-fmt:
	cd $(TERRAFORM_DIR) && terraform fmt -recursive

# dbt Commands
.PHONY: dbt-deps
dbt-deps:
	cd $(DBT_DIR) && dbt deps

.PHONY: dbt-run
dbt-run:
	cd $(DBT_DIR) && dbt run

.PHONY: dbt-test
dbt-test:
	cd $(DBT_DIR) && dbt test

.PHONY: dbt-docs
dbt-docs:
	cd $(DBT_DIR) && dbt docs generate && dbt docs serve

.PHONY: dbt-debug
dbt-debug:
	cd $(DBT_DIR) && dbt debug

.PHONY: dbt-seed
dbt-seed:
	cd $(DBT_DIR) && dbt seed

.PHONY: dbt-snapshot
dbt-snapshot:
	cd $(DBT_DIR) && dbt snapshot

# Airflow Commands
.PHONY: airflow-init
airflow-init:
	cd $(AIRFLOW_DIR) && airflow db init

.PHONY: airflow-start
airflow-start:
	cd $(AIRFLOW_DIR) && airflow webserver -p 8080 &
	cd $(AIRFLOW_DIR) && airflow scheduler &

.PHONY: airflow-test
airflow-test:
	cd $(AIRFLOW_DIR) && python -m pytest tests/

.PHONY: airflow-list-dags
airflow-list-dags:
	cd $(AIRFLOW_DIR) && airflow dags list

.PHONY: airflow-test-dag
airflow-test-dag:
	cd $(AIRFLOW_DIR) && airflow dags test $(DAG_ID) $(EXECUTION_DATE)

# Data Pipeline Commands
.PHONY: validate-data-sources
validate-data-sources:
	python python-scripts/utils/test_connections.py

.PHONY: ingest-sample-data
ingest-sample-data:
	python python-scripts/ingestion/alpha_vantage_client.py --sample
	python python-scripts/ingestion/yahoo_finance_client.py --sample

.PHONY: run-data-quality-checks
run-data-quality-checks:
	python python-scripts/utils/data_quality.py

# Deployment Commands
.PHONY: deploy-infra
deploy-infra: tf-init tf-validate tf-plan tf-apply

.PHONY: deploy-dbt
deploy-dbt: dbt-deps dbt-debug dbt-run dbt-test

.PHONY: deploy-airflow
deploy-airflow:
	@echo "Uploading DAGs to S3..."
	aws s3 sync $(AIRFLOW_DIR)/dags/ s3://$(S3_BUCKET_AIRFLOW)/dags/
	aws s3 sync $(AIRFLOW_DIR)/plugins/ s3://$(S3_BUCKET_AIRFLOW)/plugins/
	aws s3 cp $(AIRFLOW_DIR)/config/requirements.txt s3://$(S3_BUCKET_AIRFLOW)/requirements.txt

.PHONY: deploy-pipeline
deploy-pipeline: deploy-dbt deploy-airflow

.PHONY: deploy-all
deploy-all: deploy-infra deploy-pipeline

# Monitoring Commands
.PHONY: check-pipeline-health
check-pipeline-health:
	python scripts/utilities/test_connections.py
	cd $(DBT_DIR) && dbt run-operation check_data_freshness

.PHONY: view-logs
view-logs:
	aws logs tail /aws/mwaa/$(PROJECT_NAME) --follow

.PHONY: check-s3-data
check-s3-data:
	aws s3 ls s3://$(S3_BUCKET_RAW_DATA)/ --recursive --human-readable --summarize

# Backup Commands
.PHONY: backup-redshift
backup-redshift:
	bash scripts/utilities/backup_redshift.sh

.PHONY: backup-s3
backup-s3:
	aws s3 sync s3://$(S3_BUCKET_RAW_DATA)/ ./backups/s3-raw-data/
	aws s3 sync s3://$(S3_BUCKET_PROCESSED_DATA)/ ./backups/s3-processed-data/

# Development Environment
.PHONY: start-local-dev
start-local-dev:
	docker-compose up -d
	@echo "Local development environment started"

.PHONY: stop-local-dev
stop-local-dev:
	docker-compose down
	@echo "Local development environment stopped"

.PHONY: reset-local-dev
reset-local-dev:
	docker-compose down -v
	docker-compose up -d
	@echo "Local development environment reset"

# Data Analysis
.PHONY: run-analysis
run-analysis:
	jupyter notebook docs/analysis/

.PHONY: generate-reports
generate-reports:
	python scripts/utilities/generate_reports.py

# Security
.PHONY: scan-secrets
scan-secrets:
	git secrets --scan

.PHONY: audit-dependencies
audit-dependencies:
	pip-audit

# Cleanup Commands
.PHONY: clean
clean:
	find . -type f -name "*.pyc" -delete
	find . -type d -name "__pycache__" -delete
	find . -type d -name "*.egg-info" -exec rm -rf {} +
	find . -type f -name "*.log" -delete
	rm -rf .pytest_cache
	rm -rf .coverage
	rm -rf htmlcov
	rm -rf $(DBT_DIR)/target
	rm -rf $(DBT_DIR)/logs
	rm -rf $(DBT_DIR)/dbt_packages

.PHONY: clean-terraform
clean-terraform:
	cd $(TERRAFORM_DIR) && rm -rf .terraform
	cd $(TERRAFORM_DIR) && rm -f .terraform.lock.hcl
	cd $(TERRAFORM_DIR) && rm -f terraform.tfstate*

.PHONY: clean-all
clean-all: clean clean-terraform
	rm -rf $(VENV_NAME)
	rm -rf .env
	@echo "All temporary files and virtual environment cleaned"

# Quick commands for daily workflow
.PHONY: quick-setup
quick-setup: setup-env setup-pre-commit
	@echo "Quick setup completed"

.PHONY: quick-deploy
quick-deploy: format lint test deploy-all
	@echo "Quick deployment completed"

.PHONY: quick-test
quick-test: format lint test dbt-test airflow-test
	@echo "All tests completed"

# Environment-specific commands
.PHONY: deploy-dev
deploy-dev:
	@echo "Deploying to development environment"
	export ENVIRONMENT=dev && make deploy-all

.PHONY: deploy-prod
deploy-prod:
	@echo "Deploying to production environment"
	export ENVIRONMENT=prod && make deploy-all

# Documentation
.PHONY: docs
docs:
	mkdocs serve

.PHONY: docs-build
docs-build:
	mkdocs build

.PHONY: docs-deploy
docs-deploy:
	mkdocs gh-deploy