from __future__ import annotations

import logging
from pathlib import Path
from typing import Any, Dict, Mapping

import pandas as pd
import psycopg2

from sectoral.airflow_compat import BaseOperator
from sectoral.analytics import compute_correlations, generate_insights
from sectoral.config import SectoralConfig, resolve_dates
from sectoral.export import export_results
from sectoral.ingestion import ingest_data
from sectoral.transforms import aggregate_by_sector, compute_symbol_metrics

logger = logging.getLogger(__name__)


class SectoralIngestionOperator(BaseOperator):
    """
    Ingests market data for configured sectors and writes raw data to local storage.

    :param config_path: Path to sectoral YAML config (default: config/sectoral.yaml)
    :param output_dir: Directory to write raw CSV files (default: /opt/airflow/local_s3)
    """

    template_fields = ("config_path", "output_dir")

    def __init__(
        self,
        config_path: str = "config/sectoral.yaml",
        output_dir: str = "/opt/airflow/local_s3",
        **kwargs: Any,
    ) -> None:
        super().__init__(**kwargs)
        self.config_path = Path(config_path)
        self.output_dir = Path(output_dir)

    def execute(self, context: Mapping[str, Any]) -> Dict[str, Any]:
        logger.info("Loading config from %s", self.config_path)
        cfg = SectoralConfig.from_yaml(self.config_path)
        start_date, end_date = resolve_dates(cfg.days_back)

        logger.info("Ingesting data from %s to %s", start_date, end_date)
        raw = ingest_data(cfg.sectors, start_date, end_date)

        logger.info("Writing raw data to %s", self.output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)

        for symbol, df in raw.items():
            out_path = self.output_dir / f"{symbol}.csv"
            df.to_csv(out_path, index=True)
            logger.info("Wrote %s (%d rows)", out_path, len(df))

        # Return value is automatically pushed to XCom - no need to access ti
        return {
            "num_symbols": len(raw),
            "symbols_ingested": list(raw.keys()),
            "start_date": start_date,
            "end_date": end_date,
        }


class SectoralTransformOperator(BaseOperator):
    """
    Computes symbol-level metrics, aggregates by sector, computes correlations,
    generates insights, and exports results.

    :param config_path: Path to sectoral YAML config
    :param input_dir: Directory to read raw CSV files from (default: /opt/airflow/local_s3)
    :param output_dir: Directory to write exports (default: outputs/)
    """

    template_fields = ("config_path", "input_dir", "output_dir")

    def __init__(
        self,
        config_path: str = "config/sectoral.yaml",
        input_dir: str = "/opt/airflow/local_s3",
        output_dir: str = "outputs",
        **kwargs: Any,
    ) -> None:
        super().__init__(**kwargs)
        self.config_path = Path(config_path)
        self.input_dir = Path(input_dir)
        self.output_dir = Path(output_dir)

    def execute(self, context: Mapping[str, Any]) -> dict[str, Any]:
        logger.info("Loading config from %s", self.config_path)
        cfg = SectoralConfig.from_yaml(self.config_path)

        logger.info("Reading raw data from %s", self.input_dir)
        raw = self._read_raw_data(cfg)

        logger.info("Computing symbol-level metrics")
        symbol_data = compute_symbol_metrics(raw)

        logger.info("Aggregating by sector")
        sector_data = aggregate_by_sector(cfg.sectors, symbol_data)

        logger.info("Computing correlations and insights")
        corr = compute_correlations(sector_data)
        insights = generate_insights(sector_data, corr)

        logger.info("Exporting results to %s", self.output_dir)
        export_results(symbol_data, sector_data, corr, output_dir=str(self.output_dir))

        return {
            "num_symbols": len(symbol_data),
            "num_sectors": len(sector_data),
            "insights_count": len(insights),
        }

    def _read_raw_data(self, cfg: SectoralConfig) -> dict[str, Any]:
        """Read raw CSV files back into memory."""
        import pandas as pd

        raw: dict[str, Any] = {}
        all_symbols = [sym for syms in cfg.sectors.values() for sym in syms]

        for symbol in all_symbols:
            csv_path = self.input_dir / f"{symbol}.csv"
            if csv_path.exists():
                raw[symbol] = pd.read_csv(csv_path, index_col=0, parse_dates=True)
                logger.info("Loaded %s (%d rows)", symbol, len(raw[symbol]))
            else:
                logger.warning("Missing raw data for %s", symbol)

        return raw


class PostgresLoaderOperator(BaseOperator):
    """Load CSV files to Postgres raw tables"""

    ui_color = "#3498db"

    def __init__(self, outputs_dir="/opt/airflow/outputs", **kwargs):
        super().__init__(**kwargs)
        self.outputs_dir = outputs_dir

    def execute(self, context):
        conn = psycopg2.connect(
            host="postgres",
            port="5432",
            database="airflow",
            user="airflow",
            password="airflow",
        )

        # Truncate tables first (idempotent)
        cursor = conn.cursor()
        cursor.execute("TRUNCATE TABLE raw_stock_prices, raw_sector_data;")
        conn.commit()

        outputs_path = Path(self.outputs_dir)

        # Load stock prices
        stock_files = list(outputs_path.glob("sectoral_stock_prices*.csv"))
        for csv_file in stock_files:
            df = pd.read_csv(csv_file)
            df.to_sql("raw_stock_prices", conn, if_exists="append", index=False)
            self.log.info(f"✅ Loaded {csv_file.name} ({len(df)} rows)")

        # Load sector data
        sector_file = outputs_path / "sectoral_sector_data.csv"
        if sector_file.exists():
            df = pd.read_csv(sector_file)
            df.to_sql("raw_sector_data", conn, if_exists="append", index=False)
            self.log.info(f"✅ Loaded {sector_file.name} ({len(df)} rows)")

        conn.commit()
        conn.close()
        self.log.info("✅ All CSVs loaded!")
