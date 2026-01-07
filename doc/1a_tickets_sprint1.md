# Sprint 1 – Infrastructure Foundation

## Tickets

### Ticket 1 – Repository GitHub & structure

- Initialiser le repository avec l’architecture définie dans le plan
- Créer la structure complète des dossiers
- Mettre en place les fichiers README et la documentation de base

### Ticket 2 – Terraform Base Infrastructure

- Configurer les providers AWS
- Définir variables et outputs de base
- Structurer l’infra en modules pour la scalabilité

### Ticket 3 – Buckets S3 (Data Lake)

- Bucket `raw` (données brutes) partitionné par source/date
- Bucket `processed` (données transformées)
- Bucket `logs` & configuration
- Politiques de lifecycle

### Ticket 4 – Redshift Data Warehouse

- Configuration du cluster optimisée
- Schémas pour `staging` et `marts`
- Tables de base pour les données financières

### Ticket 5 – AWS MWAA (Airflow)

- Environnement managé configuré
- Connexions vers S3 et Redshift
- Variables d’environnement (APIs, paramètres globaux)

### Ticket 6 – IAM Security

- Rôles pour Airflow, Redshift, Lambda
- Politiques de moindre privilège
- Service accounts sécurisés

---

## Structure du projet – Rappel

```text
financial-data-pipeline
├── README.md
├── .gitignore
├── requirements.txt
├── setup.py
├── .env.example
├── docker-compose.yml
├── Makefile
├── terraform
│   ├── main.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   └── modules
│       ├── s3
│       ├── redshift
│       ├── mwaa
│       └── iam
├── environments
│   ├── dev
│   └── prod
├── airflow
│   ├── dags
│   ├── utils
│   ├── plugins
│   └── config
├── python-scripts
│   ├── ingestion
│   ├── utils
│   └── tests
├── dbt
│   ├── models
│   ├── macros
│   ├── tests
│   └── snapshots
├── sql
│   ├── analytics
│   ├── ddl
│   └── maintenance
├── docs
│   ├── architecture
│   ├── setup
│   ├── api
│   ├── business
│   └── monitoring
└── scripts
    ├── setup
    ├── deployment
    └── utilities
```

---

## Fichiers principaux à créer

1. **README.md principal**
   - Description du projet
   - Vue d’architecture
   - Guide d’installation
   - Documentation des APIs
   - Métriques business

2. **.gitignore**
   - Fichiers Terraform sensibles
   - Credentials & `.env`
   - Logs & cache
   - Fichiers temporaires

3. **requirements.txt**
   - Dépendances Python
   - Versions spécifiques
   - Séparation dev/prod si nécessaire

4. **Fichiers de configuration**
   - `.env.example` (template de variables)
   - `docker-compose.yml` (dev local)
   - `Makefile` (commandes d’automatisation)

5. **Documentation**
   - Architecture & design
   - Guides d’installation
   - Documentation business
   - Références API

---

## Prochaines étapes

- Créer le repository GitHub
- Initialiser la structure des dossiers
- Créer les fichiers de base
- Configurer `.gitignore` et `requirements.txt`
- Démarrer la documentation initiale