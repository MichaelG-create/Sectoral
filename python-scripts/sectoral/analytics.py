from typing import Dict, Any

import numpy as np
import pandas as pd


def compute_correlations(sector_data: Dict[str, dict]) -> pd.DataFrame:
    print("\n🔄 Calcul des corrélations...")
    sector_returns_df = pd.DataFrame(
        {sector: data["daily_returns"] for sector, data in sector_data.items()}
    )
    corr = sector_returns_df.corr()
    print("✅ Matrice de corrélation calculée")
    return corr


def generate_insights(
    sector_data: Dict[str, dict],
    correlation_matrix: pd.DataFrame,
) -> Dict[str, Any]:
    print("\n🔄 Génération d'insights business...")
    insights: Dict[str, Any] = {}

    sector_performance = {s: d["total_return_1y"] for s, d in sector_data.items()}
    sorted_sectors = sorted(sector_performance.items(), key=lambda x: x[1], reverse=True)
    insights["top_performer"] = sorted_sectors[0]
    insights["worst_performer"] = sorted_sectors[-1]

    sector_volatility = {s: d["volatility_1y"] for s, d in sector_data.items()}
    insights["least_volatile"] = min(sector_volatility.items(), key=lambda x: x[1])

    sector_sharpe = {s: d["sharpe_ratio"] for s, d in sector_data.items()}
    best_sharpe = max(
        sector_sharpe.items(), key=lambda x: x[1] if not np.isnan(x[1]) else -999
    )
    insights["best_sharpe"] = best_sharpe

    corr_no_diag = correlation_matrix.where(
        ~np.eye(correlation_matrix.shape[0], dtype=bool)
    )

    row_idx_np, col_idx_np = np.unravel_index(
        int(np.nanargmax(corr_no_diag.values)),
        corr_no_diag.shape,
    )

    row_idx = int(row_idx_np)
    col_idx = int(col_idx_np)

    highest_corr = {
        "sectors": (
            correlation_matrix.index[row_idx],
            correlation_matrix.columns[col_idx],
        ),
        "correlation": float(correlation_matrix.iloc[row_idx, col_idx]),
    }
 
    row_min_np, col_min_np = np.unravel_index(
        int(np.nanargmin(corr_no_diag.values)),
        corr_no_diag.shape,
    )

    row_min = int(row_min_np)
    col_min = int(col_min_np)

    lowest_corr = {
        "sectors": (
            correlation_matrix.index[row_min],
            correlation_matrix.columns[col_min],
        ),
        "correlation": float(correlation_matrix.iloc[row_min, col_min]),
    }

    insights["highest_correlation"] = highest_corr
    insights["lowest_correlation"] = lowest_corr

    print("✅ Insights générés")
    return insights
