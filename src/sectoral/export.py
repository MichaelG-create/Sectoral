from typing import Dict

import pandas as pd


def export_results(
    symbol_data: Dict[str, pd.DataFrame],
    sector_data: Dict[str, dict],
    correlation_matrix: pd.DataFrame,
) -> None:
    print("\n🔄 Export des résultats...")

    all_data = pd.DataFrame()
    for symbol, data in symbol_data.items():
        temp_df = data.copy()
        temp_df["Symbol"] = symbol
        all_data = pd.concat([all_data, temp_df])

    all_data.to_csv("sectoral_raw_data.csv")
    print("✅ Données brutes exportées: sectoral_raw_data.csv")

    sector_summary = pd.DataFrame(
        {
            sector: {
                "Total_Return_1Y": data["total_return_1y"],
                "Volatility_1Y": data["volatility_1y"],
                "Sharpe_Ratio": data["sharpe_ratio"],
            }
            for sector, data in sector_data.items()
        }
    ).T

    sector_summary.to_csv("sectoral_metrics.csv")
    print("✅ Métriques sectorielles exportées: sectoral_metrics.csv")

    correlation_matrix.to_csv("sectoral_correlations.csv")
    print("✅ Corrélations exportées: sectoral_correlations.csv")


def display_summary(sector_data: Dict[str, dict], insights: Dict[str, dict]) -> None:
    print("\n" + "=" * 60)
    print("🎯 SECTORAL - RÉSUMÉ EXÉCUTIF")
    print("=" * 60)

    print("\n📈 PERFORMANCE (12 mois)")
    print(
        f"🥇 Meilleur secteur: {insights['top_performer'][0]} (+{insights['top_performer'][1]:.2%})"
    )
    print(
        f"🥉 Pire secteur: {insights['worst_performer'][0]} ({insights['worst_performer'][1]:.2%})"
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
