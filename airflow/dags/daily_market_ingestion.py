from __future__ import annotations

from datetime import datetime, timedelta
from typing import Any, Dict

from airflow.operators.bash import BashOperator

from airflow import DAG
from sectoral.operators import (
    PostgresLoaderOperator,
    SectoralIngestionOperator,
    SectoralTransformOperator,
)

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

    transform_task = SectoralTransformOperator(
        task_id="transform_and_export",
        config_path="config/sectoral.yaml",
        input_dir="/opt/airflow/local_s3",
        output_dir="outputs",
    )

    load_task = PostgresLoaderOperator(
        task_id="load_to_postgres",
        outputs_dir="/opt/airflow/outputs",
    )

    dbt_task = BashOperator(
        task_id="run_dbt",
        bash_command="cd /opt/airflow/dbt && dbt run && dbt test",
    )

    # Set task dependencies
    ingest_task >> transform_task >> load_task >> dbt_task
