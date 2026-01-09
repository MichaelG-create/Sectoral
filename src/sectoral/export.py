from typing import Dict

import pandas as pd


def export_results(
    symbol_data: Dict[str, pd.DataFrame],
    sector_data: Dict[str, dict],
    corr: pd.DataFrame,
    output_dir: str = "outputs",
) -> None:
    """
    Export symbol metrics, sector aggregates, and correlation matrix to CSV.
    """
    from pathlib import Path

    out = Path(output_dir)
    out.mkdir(parents=True, exist_ok=True)

    # Symbol-level metrics
    all_symbols = []
    for symbol, df in symbol_data.items():
        df_copy = df.copy()
        df_copy["Symbol"] = symbol
        all_symbols.append(df_copy)

    if all_symbols:
        pd.concat(all_symbols).to_csv(out / "symbol_metrics.csv")

    # Sector aggregates
    sector_rows = []
    for sector, data in sector_data.items():
        sector_rows.append(
            {
                "Sector": sector,
                "Cumulative_Return": data.get("cumulative_return"),
                "Volatility": data.get("volatility"),
                "Sharpe_Ratio": data.get("sharpe_ratio"),
            }
        )
    pd.DataFrame(sector_rows).to_csv(out / "sector_aggregates.csv", index=False)

    # Correlation matrix
    corr.to_csv(out / "sector_correlation.csv")

    print(f"\n✅ Exports saved to {out}/")


def display_summary(sector_data: Dict[str, dict], insights: Dict[str, dict]) -> None:
    print("\n" + "=" * 60)
    print("🎯 SECTORAL - RÉSUMÉ EXÉCUTIF")
    print("=" * 60)

    print("\n📈 PERFORMANCE (12 mois)")
    print(
        f"🥇 Meilleur secteur: {insights['top_performer'][0]} (+{insights['top_performer'][1]:.2%})"
    )
    print(
        f"🥉 Pire secteur: {insights['bottom_performer'][0]} ({insights['bottom_performer'][1]:.2%})"
    )

    print("\n⚡ RISQUE")
    print(
        f"🛡️  Moins volatil: {insights['least_volatile'][0]} ({insights['least_volatile'][1]:.2%} vol.)"
    )
    print(
        f"🏆 Meilleur Sharpe: {insights['best_sharpe'][0]} ({insights['best_sharpe'][1]:.2f})"
    )

    high_corr = insights["highest_correlation"]
    low_corr = insights["lowest_correlation"]

    print("\n🔗 CORRÉLATIONS")
    print(
        f"➕ Plus corrélés: {high_corr['sectors'][0]} ↔ {high_corr['sectors'][1]} ({high_corr['correlation']:.2f})"
    )
    print(
        f"➖ Moins corrélés: {low_corr['sectors'][0]} ↔ {low_corr['sectors'][1]} ({low_corr['correlation']:.2f})"
    )

    print("\n📊 MÉTRIQUES DÉTAILLÉES")
    for sector, data in sector_data.items():
        print(
            f"{sector:12} | Rdt: {data['total_return_1y']:+6.2%} | Vol: {data['volatility_1y']:5.2%} | Sharpe: {data['sharpe_ratio']:5.2f}"
        )

    print("\n" + "=" * 60)
    print("✅ POC Sectoral terminée avec succès!")
    print("📁 Fichiers générés: sectoral_*.csv")
    print("=" * 60)
