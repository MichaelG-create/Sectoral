import logging
from typing import Dict, Any

from .config import SectoralConfig, resolve_dates
from .ingestion import ingest_data
from .transforms import compute_symbol_metrics, aggregate_by_sector
from .analytics import compute_correlations, generate_insights
from .export import export_results, display_summary

logger = logging.getLogger(__name__)


def run_pipeline() -> Dict[str, Any]:
    cfg = SectoralConfig.from_yaml()
    start_date, end_date = resolve_dates(cfg.days_back)

    logger.info("Ingesting data from %s to %s", start_date, end_date)
    raw = ingest_data(cfg.sectors, start_date, end_date)

    logger.info("Computing symbol-level metrics")
    symbol_data = compute_symbol_metrics(raw)

    logger.info("Aggregating by sector")
    sector_data = aggregate_by_sector(cfg.sectors, symbol_data)

    logger.info("Computing correlations and insights")
    corr = compute_correlations(sector_data)
    insights = generate_insights(sector_data, corr)

    logger.info("Exporting results")
    export_results(symbol_data, sector_data, corr)
    display_summary(sector_data, insights)

    return {
        "num_symbols": len(raw),
        "num_sectors": len(sector_data),
    }


def main() -> int:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s | %(name)s | %(levelname)s | %(message)s",
    )

    logger.info("Starting Sectoral POC run")
    try:
        metrics = run_pipeline()
        logger.info("Run completed: %s", metrics)
    except Exception:
        logger.exception("Sectoral POC run failed")
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
