# POC Sectoral – Présentation

## Objectif de la POC

Cette POC démontre un pipeline complet d’analyse sectorielle à partir de données financières réelles.

## Fonctionnalités démontrées

- **Pipeline complet**
  - Ingestion de 20 actions réparties sur 5 secteurs via Yahoo Finance
  - Transformation des données : rendements, volatilité, moyennes mobiles
  - Agrégation en métriques sectorielles consolidées
  - Analytics : corrélations inter‑sectorielles, insights business
  - Export de 3 fichiers CSV de résultats

## Métriques calculées

- Rendements totaux par secteur sur 1 an
- Volatilité annualisée
- Ratios de Sharpe
- Matrice de corrélations
- Top/Flop performers

## Exécution de la POC

### Prérequis

```bash
pip install yfinance pandas numpy
python sectoralpoc.py
```

### Outputs attendus

- `sectoral_raw_data.csv` : données brutes pour toutes les actions
- `sectoral_metrics.csv` : métriques agrégées par secteur
- `sectoral_correlations.csv` : matrice de corrélations

Un résumé exécutif est affiché dans le terminal à la fin de l’exécution.

## Valeur démontrée par la POC

- Ingestion de données financières réelles
- Transformations business pertinentes
- Analytics sectorielles avancées
- Export pour consommation downstream

Une fois la POC validée, on pourra passer à l’architecture complète (Airflow, AWS, dbt, etc.).
