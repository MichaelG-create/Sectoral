from typing import Dict, List

import pandas as pd
import yfinance as yf


def ingest_data(
    sectors_stocks: Dict[str, List[str]],
    start_date: str,
    end_date: str,
) -> Dict[str, pd.DataFrame]:
    print("🔄 Ingestion des données financières...")
    raw_data: Dict[str, pd.DataFrame] = {}

    all_symbols = [stock for stocks in sectors_stocks.values() for stock in stocks]

    for symbol in all_symbols:
        try:
            ticker = yf.Ticker(symbol)
            data = ticker.history(start=start_date, end=end_date)

            if not data.empty:
                raw_data[symbol] = data
                print(f"✅ {symbol}: {len(data)} jours de données")
            else:
                print(f"❌ {symbol}: Aucune donnée")
        except Exception as e:
            print(f"❌ Erreur pour {symbol}: {e}")

    print(f"\n📊 Total: {len(raw_data)} actions ingérées")
    return raw_data
