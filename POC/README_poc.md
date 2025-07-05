# SECTORAL POC

## 🎯 Fonctionnalités démontrées
Pipeline complet :

Ingestion : 20 actions réparties sur 5 secteurs via Yahoo Finance
Transformation : Calculs de rendements, volatilité, moyennes mobiles
Agrégation : Métriques sectorielles consolidées
Analytics : Corrélations inter-sectorielles, insights business
Export : 3 fichiers CSV de résultats

## 📊 Métriques calculées

Rendements totaux par secteur (1 an)
Volatilité annualisée
Ratios de Sharpe
Matrice de corrélations
Top/Flop performers

## 🚀 Pour exécuter
```bash
pip install yfinance pandas numpy
python sectoral_poc.py
```
## 📁 Outputs attendus

sectoral_raw_data.csv - Données brutes toutes actions
sectoral_metrics.csv - Métriques par secteur
sectoral_correlations.csv - Matrice de corrélations
Résumé exécutif dans le terminal

Cette POC démontre :
✅ Ingestion de données financières réelles
✅ Transformations business pertinentes
✅ Analytics sectorielles avancées
✅ Export pour usage downstream