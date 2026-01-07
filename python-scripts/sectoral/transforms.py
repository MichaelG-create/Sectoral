from typing import Dict

import numpy as np
import pandas as pd


def compute_symbol_metrics(raw_data: Dict[str, pd.DataFrame]) -> Dict[str, pd.DataFrame]:
    print("\n🔄 Calcul des rendements et métriques...")
    out: Dict[str, pd.DataFrame] = {}

    for symbol, data in raw_data.items():
        df = data.copy()
        df["Daily_Return"] = df["Close"].pct_change()
        df["Cumulative_Return"] = (1 + df["Daily_Return"]).cumprod() - 1
        df["Volatility_30d"] = df["Daily_Return"].rolling(30).std() * np.sqrt(252)
        df["MA_20"] = df["Close"].rolling(20).mean()
        df["MA_50"] = df["Close"].rolling(50).mean()
        out[symbol] = df

    print("✅ Métriques individuelles calculées")
    return out


def aggregate_by_sector(
    sectors_stocks: Dict[str, list[str]],
    symbol_data: Dict[str, pd.DataFrame],
) -> Dict[str, dict]:
    print("\n🔄 Agrégation par secteur...")
    sector_data: Dict[str, dict] = {}

    for sector, stocks in sectors_stocks.items():
        sector_returns = []

        for stock in stocks:
            if stock in symbol_data:
                sector_returns.append(symbol_data[stock]["Daily_Return"])

        if sector_returns:
            sector_df = pd.DataFrame(sector_returns).T
            sector_return = sector_df.mean(axis=1)

            sector_data[sector] = {
                "daily_returns": sector_return,
                "cumulative_return": (1 + sector_return).cumprod() - 1,
                "volatility": sector_return.rolling(30).std() * np.sqrt(252),
                "total_return_1y": ((1 + sector_return).cumprod() - 1).iloc[-1],
                "volatility_1y": sector_return.std() * np.sqrt(252),
                "sharpe_ratio": (sector_return.mean() * 252)
                / (sector_return.std() * np.sqrt(252)),
            }

            print(f"✅ {sector}: Rendement 1Y = {sector_data[sector]['total_return_1y']:.2%}")

    return sector_data
