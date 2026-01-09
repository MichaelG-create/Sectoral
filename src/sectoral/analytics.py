from typing import Any, Dict

import numpy as np
import pandas as pd


def compute_correlations(sector_data: Dict[str, dict]) -> pd.DataFrame:
    """Compute Pearson correlations between sector daily returns."""
    print("\n🔄 Calcul des corrélations...")

    if not sector_data:
        # Aucune donnée : renvoyer une matrice vide cohérente
        print("⚠️ Aucune donnée de rendement disponible, matrice de corrélation vide")
        return pd.DataFrame()

    sector_returns_df = pd.DataFrame(
        {sector: data["daily_returns"] for sector, data in sector_data.items()}
    )

    # Si le DataFrame est vide ou ne contient qu'une seule série, corr() sera
    # soit vide, soit 1x1 (corr=1 avec soi-même). [web:17][web:27]
    corr = sector_returns_df.corr()
    print("✅ Matrice de corrélation calculée")
    return corr


def generate_insights(
    sector_data: Dict[str, dict],
    correlation_matrix: pd.DataFrame,
) -> Dict[str, Any]:
    """Generate business insights from sector performance and correlations."""
    print("\n🔄 Génération d'insights business...")
    insights: Dict[str, Any] = {}

    # Cas sans données : renvoyer un dictionnaire typé mais sans valeurs chiffrées.
    if not sector_data or correlation_matrix is None or correlation_matrix.empty:
        insights["top_performer"] = None
        insights["bottom_performer"] = None
        insights["performance_spread"] = None
        insights["least_volatile"] = None
        insights["best_sharpe"] = None
        insights["highest_correlation"] = None
        insights["lowest_correlation"] = None
        print("⚠️ Aucune donnée suffisante pour générer des insights")
        return insights

    # --- Performance / volatilité / Sharpe ---

    sector_performance = {s: d["total_return_1y"] for s, d in sector_data.items()}
    sorted_sectors = sorted(
        sector_performance.items(), key=lambda x: x[1], reverse=True
    )

    # On sait ici que sector_data n'est pas vide, donc sorted_sectors non plus.
    insights["top_performer"] = sorted_sectors[0]
    insights["bottom_performer"] = sorted_sectors[-1]
    insights["performance_spread"] = (
        sorted_sectors[0][1] - sorted_sectors[-1][1] if len(sorted_sectors) > 1 else 0.0
    )

    sector_volatility = {s: d["volatility_1y"] for s, d in sector_data.items()}
    insights["least_volatile"] = min(sector_volatility.items(), key=lambda x: x[1])

    sector_sharpe = {s: d["sharpe_ratio"] for s, d in sector_data.items()}
    insights["best_sharpe"] = max(
        sector_sharpe.items(),
        key=lambda x: x[1] if not np.isnan(x[1]) else -999.0,
    )

    # --- Corrélations ---

    # Si la matrice est 1x1, il n'y a pas de paires distinctes à analyser.
    if correlation_matrix.shape[0] < 2:
        insights["highest_correlation"] = None
        insights["lowest_correlation"] = None
        print(
            "⚠️ Matrice de corrélation sans paires distinctes, aucun insight de corrélation"
        )
        print("✅ Insights générés")
        return insights

    # Masquer la diagonale (corrélation d'un secteur avec lui-même). [web:23][web:26]
    mask_diag = np.eye(correlation_matrix.shape[0], dtype=bool)
    corr_no_diag = correlation_matrix.where(~mask_diag)

    # Plate matrices pour nanargmax / nanargmin ; lève ValueError si tout est NaN. [web:31][web:25]
    values = corr_no_diag.values

    if np.all(np.isnan(values)):
        insights["highest_correlation"] = None
        insights["lowest_correlation"] = None
        print("⚠️ Toutes les corrélations hors diagonale sont NaN")
        print("✅ Insights générés")
        return insights

    # Plus haute corrélation
    max_flat_idx: int = int(np.nanargmax(values))
    row_idx_arr, col_idx_arr = np.unravel_index(max_flat_idx, corr_no_diag.shape)
    row_idx: int = int(row_idx_arr)
    col_idx: int = int(col_idx_arr)

    value = correlation_matrix.iloc[row_idx, col_idx]

    # Typage plus précis pour Pylance
    corr_value: float
    if isinstance(value, (float, int, np.floating)):
        corr_value = float(value)
    else:
        # fallback défensif, au cas où le dtype serait exotique
        corr_value = float(np.asarray(value, dtype="float64"))

    highest_corr = {
        "sectors": (
            str(correlation_matrix.index[row_idx]),
            str(correlation_matrix.columns[col_idx]),
        ),
        "correlation": corr_value,
    }

    # Plus faible corrélation
    min_flat_idx: int = int(np.nanargmin(values))
    row_min_arr, col_min_arr = np.unravel_index(min_flat_idx, corr_no_diag.shape)
    row_min: int = int(row_min_arr)
    col_min: int = int(col_min_arr)

    value_min = correlation_matrix.iloc[row_min, col_min]

    lowest_corr_value: float
    if isinstance(value_min, (float, int, np.floating)):
        lowest_corr_value = float(value_min)
    else:
        lowest_corr_value = float(np.asarray(value_min, dtype="float64"))

    lowest_corr = {
        "sectors": (
            str(correlation_matrix.index[row_min]),
            str(correlation_matrix.columns[col_min]),
        ),
        "correlation": lowest_corr_value,
    }

    insights["highest_correlation"] = highest_corr
    insights["lowest_correlation"] = lowest_corr

    print("✅ Insights générés")
    return insights
