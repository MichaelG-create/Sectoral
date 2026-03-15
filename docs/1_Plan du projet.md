# Projet Data Engineering – Analyse des Performances Sectorielles

## Objectif business

Créer un pipeline automatisé d’analyse des performances sectorielles des marchés financiers pour identifier les tendances d’investissement et générer des insights business.

---

## Architecture technique

### Stack technologique

- Orchestration : Apache Airflow (GCP Cloud Composer)
- Infrastructure : Terraform (GCP)
- Ingestion : Python (pandas, requests, boto3)
- Stockage : GCS (Data Lake)
- Data Warehouse : Google BigQuery
- Transformation : dbt Core
- Monitoring : CloudWatch, UI Airflow

### Architecture des données

- APIs financières → Python (ingestion) → GCS Raw
- dbt (transform) → BigQuery (analytics)
- Airflow DAGs (orchestration) sur l’ensemble du pipeline

---

## Sources de données

### APIs gratuites

- **Alpha Vantage**
  - 5 calls/min, 500/jour
  - Prix d’actions quotidiens
  - Données sectorielles
- **Yahoo Finance (yfinance)**
  - Prix historiques
  - Métadonnées entreprises
- **FRED API (Federal Reserve)**
  - Taux d’intérêt
  - Indicateurs macro‑économiques

### Données collectées

- **Actions**
  - Prix OHLCV
  - Volumes
  - Capitalisation
- **Secteurs (GICS)**
  - Technology, Healthcare, Finance, etc.
- **Indices**
  - S&P 500
  - Indices sectoriels
- **Macro**
  - Taux Fed
  - Inflation
  - VIX

---

## Structure du projet

```text
financial-data-pipeline
├── terraform
│   ├── main.tf
│   ├── gcp.tf
│   ├── bigquery.tf
│   ├── cloudcomposer.tf
│   └── variables.tf
├── airflow
│   ├── dags
│   │   ├── daily_market_ingestion.py
│   │   ├── weekly_sector_analysis.py
│   │   └── monthly_portfolio_rebalance.py
│   └── plugins
├── python-scripts
│   └── ingestion
│       ├── alphavantage_client.py
│       ├── yahoofinance_client.py
│       └── data_validator.py
├── dbt
│   └── models
│       ├── staging
│       ├── intermediate
│       └── marts
└── sql
    └── analytics
```

---

## Plan de développement

### Phase 1 – Infrastructure (Semaine 1)

- Setup Terraform
  - Provisioning GCS, BigQuery, Cloud Composer, IAM
  - Configuration networking et sécurité
- Setup Airflow
  - Configuration Cloud Composer
  - Connexions vers les services GCP
  - Variables d’environnement

### Phase 2 – Ingestion (Semaine 2)

- Scripts Python d’ingestion
  - Clients APIs Alpha Vantage, Yahoo Finance, FRED
  - Validation et nettoyage des données
  - Upload vers GCS (Parquet partitionné)
- DAGs Airflow
  - Pipeline quotidien d’ingestion
  - Gestion des erreurs et retry
  - Notifications en cas d’échec

### Phase 3 – Transformation (Semaine 3)

- Modèles dbt
  - **Staging** : nettoyage, standardisation
  - **Intermediate** : calculs de métriques (volatilité, rendements, etc.)
  - **Marts** : modèles business (performances sectorielles)
- Tests dbt
  - Qualité des données
  - Cohérence business

### Phase 4 – Analytics business (Semaine 4)

- Requêtes SQL avancées
  - Analyses de corrélations sectorielles
  - Détection de tendances
  - Signaux d’investissement
- Dashboard & reporting
  - Requêtes pour visualisation
  - KPIs business

---

## Cas d’usage business

1. **Analyse de performance sectorielle**
   - Comparaison des rendements par secteur (YTD, 1M, 3M, 1Y)
   - Identification des secteurs sur/sous‑performants
   - Corrélations entre secteurs et indices macro

2. **Détection de tendances**
   - Momentum sectoriel (moving averages)
   - Volatilité relative par secteur
   - Signaux de rotation sectorielle

3. **Risk management**
   - Calcul de VaR par secteur
   - Analyse de drawdown
   - Diversification optimale

---

## Métriques techniques calculées

### Rendements

- Rendement quotidien : \((close - close_{lag1}) / close_{lag1}\)
- Rendement cumulatif
- Ratio de Sharpe par secteur
- Alpha/Beta vs marché

### Volatilité

- Volatilité 30 jours
- Exemple SQL :
  ```sql
  STDDEV(daily_return) OVER (
      PARTITION BY symbol
      ORDER BY date
      ROWS 29 PRECEDING
  )
  ```

### Corrélations

- Corrélation secteur vs S&P 500
- Fenêtre 1 an (environ 252 jours de trading)

---

## Objectifs d’apprentissage

### Compétences data engineering

- Architecture cloud moderne (GCP)
- Orchestration complexe avec Airflow
- Infrastructure as Code (Terraform)
- Transformations SQL avancées (dbt)
- Mise en place d’un pipeline de données robuste

### Compétences business/finance

- Métriques financières
- Analyse sectorielle
- Risk management
- Trading signals

---

## Livrables finaux

- Repository GitHub avec documentation
- Diagramme d’architecture (infrastructure & data flow)
- Dashboard d’analytics
- Requêtes et métriques business
- Documentation :
  - Setup guide
  - Business insights
- Présentation de démonstration du projet

---

## Pipeline quotidien (type)

- 06:00 – Ingestion des données overnight
- 06:30 – Validation qualité des données
- 07:00 – Transformations dbt
- 07:30 – Tests et checks
- 08:00 – Mise à jour des métriques business
- 08:30 – Génération d’alertes/rapports

Ce projet illustre une expertise complète en data engineering moderne avec un focus business concret sur les marchés financiers.
