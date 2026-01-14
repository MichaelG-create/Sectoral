from __future__ import annotations

from datetime import datetime, timedelta
from typing import Any, Dict

from airflow.operators.bash import BashOperator

from airflow import DAG
from sectoral.operators import PostgresLoaderOperator, SectoralIngestionOperator

default_args: Dict[str, Any] = {
    "owner": "data-engineering",
    "depends_on_past": False,
    "start_date": datetime(2024, 1, 1),
    "email_on_failure": True,
    "email_on_retry": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
}


with DAG(
    dag_id="daily_market_ingestion",
    default_args=default_args,
    description="Pipeline quotidien d'ingestion des données de marché",
    schedule="0 6 * * 1-5",  # 6 AM weekdays
    catchup=False,
    tags=["sectoral", "daily", "market-data"],
) as dag:

    ingest_task = SectoralIngestionOperator(
        task_id="ingest_stock_data",
        config_path="config/sectoral.yaml",
        output_dir="/opt/airflow/local_s3",
    )

    load_task = PostgresLoaderOperator(
        task_id="load_to_postgres",
        input_dir="/opt/airflow/local_s3",
    )

    dbt_task = BashOperator(
        task_id="run_dbt",
        bash_command="cd /opt/airflow/dbt && dbt run && dbt test",
    )

    # Simplified dependencies: ingest → load → dbt
    ingest_task >> load_task >> dbt_task
