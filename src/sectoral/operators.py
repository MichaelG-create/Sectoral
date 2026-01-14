from __future__ import annotations

import logging
from pathlib import Path
from typing import Any, Dict, Mapping

import pandas as pd
from sqlalchemy.engine.create import create_engine
from sqlalchemy.sql.expression import text

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

    def __init__(self, input_dir="/opt/airflow/local_s3", **kwargs):
        super().__init__(**kwargs)
        self.input_dir = input_dir

    def execute(self, context):
        engine = create_engine("postgresql://airflow:airflow@postgres:5432/airflow")

        with engine.begin() as conn:
            # Truncate tables
            conn.execute(text("TRUNCATE TABLE raw_stock_prices, raw_sector_data;"))

            # Load stock CSVs
            input_path = Path(self.input_dir)
            stock_files = list(input_path.glob("*.csv"))

            for csv_file in stock_files:
                symbol = csv_file.stem.lower()
                df = pd.read_csv(csv_file)

                # Prepare data
                df["symbol"] = symbol
                df.rename(columns={"Date": "ts"}, inplace=True)
                df = df[["symbol", "ts", "Open", "High", "Low", "Close", "Volume"]]
                df.columns = ["symbol", "ts", "open", "high", "low", "close", "volume"]

                # Insert with raw SQL
                for _, row in df.iterrows():
                    conn.execute(
                        text(
                            """
                            INSERT INTO raw_stock_prices (symbol, ts, open, high, low, close, volume)
                            VALUES (:symbol, :ts, :open, :high, :low, :close, :volume)
                        """
                        ),
                        {
                            "symbol": row["symbol"],
                            "ts": row["ts"],
                            "open": float(row["open"]),
                            "high": float(row["high"]),
                            "low": float(row["low"]),
                            "close": float(row["close"]),
                            "volume": int(row["volume"]),
                        },
                    )

                self.log.info(f"✅ Loaded {symbol}: {len(df)} rows")

            # Load sector mappings
            cfg = SectoralConfig.from_yaml()

            for sector, symbols in cfg.sectors.items():
                for symbol in symbols:
                    conn.execute(
                        text(
                            "INSERT INTO raw_sector_data (symbol, sector) VALUES (:symbol, :sector)"
                        ),
                        {"symbol": symbol.lower(), "sector": sector},
                    )

            self.log.info("✅ Loaded sector mappings")

        engine.dispose()
        self.log.info("✅ All data loaded to Postgres!")
