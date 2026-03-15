# scripts/load_raw_to_bigquery.py
from __future__ import annotations

from typing import Dict

import pandas as pd
from google.cloud import bigquery

from sectoral.config import SectoralConfig, resolve_dates
from sectoral.ingestion import ingest_data


def build_raw_stock_prices_df(raw: Dict[str, pd.DataFrame]) -> pd.DataFrame:
    """
    Transforme le dict symbol -> DataFrame en un DataFrame long
    pour raw_stock_prices (symbol, ts, open, high, low, close, volume).
    On part de la logique actuelle de tes DataFrames (index = date, colonnes OHLCV).
    """

    records = []
    for symbol, df in raw.items():
        # On suppose que df a un index de dates et des colonnes type
        # ['Open', 'High', 'Low', 'Close', 'Volume'] (adapter si besoin).
        df_local = df.copy()
        df_local = df_local.rename(
            columns={
                "Open": "open",
                "High": "high",
                "Low": "low",
                "Close": "close",
                "Volume": "volume",
            }
        )
        df_local["symbol"] = symbol
        df_local["ts"] = df_local.index

        # Garder l’ordre des colonnes attendu par dbt
        records.append(
            df_local[["symbol", "ts", "open", "high", "low", "close", "volume"]]
        )

    if not records:
        return pd.DataFrame(
            columns=["symbol", "ts", "open", "high", "low", "close", "volume"]
        )

    return pd.concat(records, ignore_index=True)


def build_raw_sector_data_df(sectors_config: Dict[str, list[str]]) -> pd.DataFrame:
    """
    Construit la table de mapping symbol -> sector à partir de config/sectoral.yaml.
    sectors_config ressemble à :
      {
        "Technology": ["AAPL", "MSFT", ...],
        "Finance": ["JPM", ...],
        ...
      }
    """
    rows = []
    for sector, symbols in sectors_config.items():
        for symbol in symbols:
            rows.append({"symbol": symbol, "sector": sector})

    return pd.DataFrame(rows, columns=["symbol", "sector"])


def load_dataframe_to_bq(
    df: pd.DataFrame,
    table_id: str,
    write_disposition: str = "WRITE_TRUNCATE",
) -> None:
    """
    Charge un DataFrame dans une table BigQuery.
    table_id: "project.dataset.table"
    """
    if df.empty:
        print(f"[INFO] DataFrame vide, rien à charger vers {table_id}")
        return

    client = bigquery.Client()  # utilise ton service account activé via env/clé

    job_config = bigquery.LoadJobConfig(
        write_disposition=write_disposition,
    )

    job = client.load_table_from_dataframe(df, table_id, job_config=job_config)
    result = job.result()
    print(f"[INFO] Chargé {result.output_rows} lignes dans {table_id}")


def main() -> int:
    # 1) Lire la config Sectoral (config/sectoral.yaml par défaut)
    cfg = SectoralConfig.from_yaml()

    # 2) Résoudre les dates d’analyse
    start_date, end_date = resolve_dates(cfg.days_back)
    print(f"[INFO] Ingestion from {start_date} to {end_date}")

    # 3) Ingestion brute via ta fonction existante
    raw = ingest_data(cfg.sectors, start_date, end_date)
    print(f"[INFO] Retrieved data for {len(raw)} symbols")

    # 4) Construire les deux DataFrames bruts
    df_prices = build_raw_stock_prices_df(raw)
    df_sectors = build_raw_sector_data_df(cfg.sectors)

    print(f"[INFO] raw_stock_prices rows: {len(df_prices)}")
    print(f"[INFO] raw_sector_data rows: {len(df_sectors)}")

    # 5) Charger dans BigQuery (adapter project/dataset si besoin)
    project_id = "sectoral-490115"
    dataset_raw = "sectoral_raw"

    table_prices = f"{project_id}.{dataset_raw}.raw_stock_prices"
    table_sectors = f"{project_id}.{dataset_raw}.raw_sector_data"

    load_dataframe_to_bq(df_prices, table_prices)
    load_dataframe_to_bq(df_sectors, table_sectors)

    print("[INFO] Done loading raw tables to BigQuery")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
