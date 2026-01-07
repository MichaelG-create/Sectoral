#!/usr/bin/env python3
import warnings
from datetime import datetime, timedelta

from python_scripts.sectoral.ingestion import ingest_data
from python_scripts.sectoral.transforms import compute_symbol_metrics, aggregate_by_sector
from python_scripts.sectoral.analytics import compute_correlations, generate_insights
from python_scripts.sectoral.export import export_results, display_summary

warnings.filterwarnings("ignore")


DEFAULT_SECTORS = {
    "Technology": ["AAPL", "MSFT", "GOOGL", "NVDA"],
    "Healthcare": ["JNJ", "PFE", "UNH", "ABBV"],
    "Finance": ["JPM", "BAC", "WFC", "GS"],
    "Energy": ["XOM", "CVX", "COP", "SLB"],
    "Consumer": ["AMZN", "TSLA", "HD", "MCD"],
}


def main() -> bool:
    print("🚀 SECTORAL - POC Data Engineering Financier")
    print("Analyse sectorielle automatisée des marchés\n")

    start_date = (datetime.now() - timedelta(days=365)).strftime("%Y-%m-%d")
    end_date = datetime.now().strftime("%Y-%m-%d")

    try:
        raw_data = ingest_data(DEFAULT_SECTORS, start_date, end_date)
        symbol_data = compute_symbol_metrics(raw_data)
        sector_data = aggregate_by_sector(DEFAULT_SECTORS, symbol_data)
        corr = compute_correlations(sector_data)
        insights = generate_insights(sector_data, corr)
        export_results(symbol_data, sector_data, corr)
        display_summary(sector_data, insights)
    except Exception as e:
        print(f"❌ Erreur dans le pipeline: {e}")
        return False

    return True


if __name__ == "__main__":
    success = main()
    if success:
        print("\n🎉 POC réussie! Prêt pour l'architecture complète.")
    else:
        print("\n💥 POC échouée. Vérifiez les dépendances et la connexion.")
