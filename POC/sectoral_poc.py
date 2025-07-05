#!/usr/bin/env python3
"""
Sectoral - POC Pipeline de données sectorielles
Démonstrateur d'ingestion et analyse de données financières
"""

import yfinance as yf
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import json
import warnings
warnings.filterwarnings('ignore')

class SectoralPOC:
    """Pipeline POC pour l'analyse sectorielle des marchés financiers"""
    
    def __init__(self):
        # Portfolio représentatif par secteur (S&P 500)
        self.sectors_stocks = {
            'Technology': ['AAPL', 'MSFT', 'GOOGL', 'NVDA'],
            'Healthcare': ['JNJ', 'PFE', 'UNH', 'ABBV'], 
            'Finance': ['JPM', 'BAC', 'WFC', 'GS'],
            'Energy': ['XOM', 'CVX', 'COP', 'SLB'],
            'Consumer': ['AMZN', 'TSLA', 'HD', 'MCD']
        }
        
        # Période d'analyse
        self.start_date = (datetime.now() - timedelta(days=365)).strftime('%Y-%m-%d')
        self.end_date = datetime.now().strftime('%Y-%m-%d')
        
        # Stockage des données
        self.raw_data = {}
        self.sector_data = {}
        self.analytics = {}
        
    def ingest_data(self):
        """Étape 1: Ingestion des données depuis Yahoo Finance"""
        print("🔄 Ingestion des données financières...")
        
        all_symbols = [stock for stocks in self.sectors_stocks.values() for stock in stocks]
        
        for symbol in all_symbols:
            try:
                ticker = yf.Ticker(symbol)
                data = ticker.history(start=self.start_date, end=self.end_date)
                
                if not data.empty:
                    self.raw_data[symbol] = data
                    print(f"✅ {symbol}: {len(data)} jours de données")
                else:
                    print(f"❌ {symbol}: Aucune donnée")
                    
            except Exception as e:
                print(f"❌ Erreur pour {symbol}: {e}")
        
        print(f"\n📊 Total: {len(self.raw_data)} actions ingérées")
        return self
    
    def calculate_returns(self):
        """Étape 2: Calcul des rendements et métriques de base"""
        print("\n🔄 Calcul des rendements et métriques...")
        
        for symbol, data in self.raw_data.items():
            # Rendements quotidiens
            data['Daily_Return'] = data['Close'].pct_change()
            
            # Rendements cumulés
            data['Cumulative_Return'] = (1 + data['Daily_Return']).cumprod() - 1
            
            # Volatilité mobile 30 jours
            data['Volatility_30d'] = data['Daily_Return'].rolling(30).std() * np.sqrt(252)
            
            # Moving averages
            data['MA_20'] = data['Close'].rolling(20).mean()
            data['MA_50'] = data['Close'].rolling(50).mean()
            
            self.raw_data[symbol] = data
            
        print("✅ Métriques individuelles calculées")
        return self
    
    def aggregate_by_sector(self):
        """Étape 3: Agrégation par secteur"""
        print("\n🔄 Agrégation par secteur...")
        
        for sector, stocks in self.sectors_stocks.items():
            sector_returns = []
            sector_prices = []
            
            for stock in stocks:
                if stock in self.raw_data:
                    sector_returns.append(self.raw_data[stock]['Daily_Return'])
                    sector_prices.append(self.raw_data[stock]['Close'])
            
            if sector_returns:
                # Moyenne pondérée égale des rendements du secteur
                sector_df = pd.DataFrame(sector_returns).T
                sector_df.columns = [f"{sector}_{stock}" for stock in stocks if stock in self.raw_data]
                
                # Rendement moyen du secteur
                sector_return = sector_df.mean(axis=1)
                
                # Métriques sectorielles
                self.sector_data[sector] = {
                    'daily_returns': sector_return,
                    'cumulative_return': (1 + sector_return).cumprod() - 1,
                    'volatility': sector_return.rolling(30).std() * np.sqrt(252),
                    'total_return_1y': ((1 + sector_return).cumprod() - 1).iloc[-1],
                    'volatility_1y': sector_return.std() * np.sqrt(252),
                    'sharpe_ratio': (sector_return.mean() * 252) / (sector_return.std() * np.sqrt(252))
                }
                
                print(f"✅ {sector}: Rendement 1Y = {self.sector_data[sector]['total_return_1y']:.2%}")
        
        return self
    
    def calculate_correlations(self):
        """Étape 4: Calcul des corrélations inter-sectorielles"""
        print("\n🔄 Calcul des corrélations...")
        
        # Matrice des rendements sectoriels
        sector_returns_df = pd.DataFrame({
            sector: data['daily_returns'] 
            for sector, data in self.sector_data.items()
        })
        
        # Matrice de corrélation
        correlation_matrix = sector_returns_df.corr()
        
        self.analytics['correlations'] = correlation_matrix
        print("✅ Matrice de corrélation calculée")
        
        return self
    
    def generate_insights(self):
        """Étape 5: Génération d'insights business"""
        print("\n🔄 Génération d'insights business...")
        
        insights = {}
        
        # Classement des secteurs par performance
        sector_performance = {
            sector: data['total_return_1y'] 
            for sector, data in self.sector_data.items()
        }
        
        sorted_sectors = sorted(sector_performance.items(), key=lambda x: x[1], reverse=True)
        
        insights['top_performer'] = sorted_sectors[0]
        insights['worst_performer'] = sorted_sectors[-1]
        
        # Secteur le moins volatil
        sector_volatility = {
            sector: data['volatility_1y'] 
            for sector, data in self.sector_data.items()
        }
        
        least_volatile = min(sector_volatility.items(), key=lambda x: x[1])
        insights['least_volatile'] = least_volatile
        
        # Meilleur ratio Sharpe
        sector_sharpe = {
            sector: data['sharpe_ratio'] 
            for sector, data in self.sector_data.items()
        }
        
        best_sharpe = max(sector_sharpe.items(), key=lambda x: x[1] if not np.isnan(x[1]) else -999)
        insights['best_sharpe'] = best_sharpe
        
        # Paires les plus/moins corrélées
        corr_matrix = self.analytics['correlations']
        
        # Masquer la diagonale
        corr_no_diag = corr_matrix.where(~np.eye(corr_matrix.shape[0], dtype=bool))
        
        # Plus haute corrélation
        max_corr_idx = np.unravel_index(np.nanargmax(corr_no_diag.values), corr_no_diag.shape)
        highest_corr = {
            'sectors': (corr_matrix.index[max_corr_idx[0]], corr_matrix.columns[max_corr_idx[1]]),
            'correlation': corr_matrix.iloc[max_corr_idx[0], max_corr_idx[1]]
        }
        
        # Plus faible corrélation
        min_corr_idx = np.unravel_index(np.nanargmin(corr_no_diag.values), corr_no_diag.shape)
        lowest_corr = {
            'sectors': (corr_matrix.index[min_corr_idx[0]], corr_matrix.columns[min_corr_idx[1]]),
            'correlation': corr_matrix.iloc[min_corr_idx[0], min_corr_idx[1]]
        }
        
        insights['highest_correlation'] = highest_corr
        insights['lowest_correlation'] = lowest_corr
        
        self.analytics['insights'] = insights
        print("✅ Insights générés")
        
        return self
    
    def export_results(self):
        """Étape 6: Export des résultats"""
        print("\n🔄 Export des résultats...")
        
        # Export données brutes en CSV
        all_data = pd.DataFrame()
        for symbol, data in self.raw_data.items():
            temp_df = data.copy()
            temp_df['Symbol'] = symbol
            all_data = pd.concat([all_data, temp_df])
        
        all_data.to_csv('sectoral_raw_data.csv')
        print("✅ Données brutes exportées: sectoral_raw_data.csv")
        
        # Export métriques sectorielles
        sector_summary = pd.DataFrame({
            sector: {
                'Total_Return_1Y': data['total_return_1y'],
                'Volatility_1Y': data['volatility_1y'], 
                'Sharpe_Ratio': data['sharpe_ratio']
            }
            for sector, data in self.sector_data.items()
        }).T
        
        sector_summary.to_csv('sectoral_metrics.csv')
        print("✅ Métriques sectorielles exportées: sectoral_metrics.csv")
        
        # Export corrélations
        self.analytics['correlations'].to_csv('sectoral_correlations.csv')
        print("✅ Corrélations exportées: sectoral_correlations.csv")
        
        return self
    
    def display_summary(self):
        """Affichage du résumé exécutif"""
        print("\n" + "="*60)
        print("🎯 SECTORAL - RÉSUMÉ EXÉCUTIF")
        print("="*60)
        
        insights = self.analytics['insights']
        
        print(f"\n📈 PERFORMANCE (12 mois)")
        print(f"🥇 Meilleur secteur: {insights['top_performer'][0]} (+{insights['top_performer'][1]:.2%})")
        print(f"🥉 Pire secteur: {insights['worst_performer'][0]} ({insights['worst_performer'][1]:.2%})")
        
        print(f"\n⚡ RISQUE")
        print(f"🛡️  Moins volatil: {insights['least_volatile'][0]} ({insights['least_volatile'][1]:.2%} vol.)")
        print(f"🏆 Meilleur Sharpe: {insights['best_sharpe'][0]} ({insights['best_sharpe'][1]:.2f})")
        
        print(f"\n🔗 CORRÉLATIONS")
        high_corr = insights['highest_correlation']
        low_corr = insights['lowest_correlation']
        print(f"➕ Plus corrélés: {high_corr['sectors'][0]} ↔ {high_corr['sectors'][1]} ({high_corr['correlation']:.2f})")
        print(f"➖ Moins corrélés: {low_corr['sectors'][0]} ↔ {low_corr['sectors'][1]} ({low_corr['correlation']:.2f})")
        
        print(f"\n📊 MÉTRIQUES DÉTAILLÉES")
        for sector, data in self.sector_data.items():
            print(f"{sector:12} | Rdt: {data['total_return_1y']:+6.2%} | Vol: {data['volatility_1y']:5.2%} | Sharpe: {data['sharpe_ratio']:5.2f}")
        
        print("\n" + "="*60)
        print("✅ POC Sectoral terminée avec succès!")
        print("📁 Fichiers générés: sectoral_*.csv")
        print("="*60)

def main():
    """Fonction principale - Exécution de la POC"""
    print("🚀 SECTORAL - POC Data Engineering Financier")
    print("Analyse sectorielle automatisée des marchés\n")
    
    # Instanciation et exécution du pipeline
    sectoral = SectoralPOC()
    
    try:
        (sectoral
         .ingest_data()
         .calculate_returns() 
         .aggregate_by_sector()
         .calculate_correlations()
         .generate_insights()
         .export_results()
         .display_summary())
         
    except Exception as e:
        print(f"❌ Erreur dans le pipeline: {e}")
        return False
    
    return True

if __name__ == "__main__":
    # Installation des dépendances requises
    print("📦 Dépendances requises:")
    print("pip install yfinance pandas numpy")
    print("-" * 40)
    
    # Exécution
    success = main()
    
    if success:
        print("\n🎉 POC réussie! Prêt pour l'architecture complète.")
    else:
        print("\n💥 POC échouée. Vérifiez les dépendances et la connexion.")