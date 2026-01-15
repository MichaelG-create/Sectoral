import os
from datetime import datetime, timedelta

import pandas as pd
import psycopg2
import streamlit as st
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Page config
st.set_page_config(page_title="Sectoral Dashboard", page_icon="📊", layout="wide")

st.title("📊 Sectoral Performance Dashboard")


# ============ DATABASE CONNECTION ============
def query_db(sql, params=None):
    """Execute query safely, creates new connection each time"""
    try:
        conn = psycopg2.connect(
            host=os.getenv("DB_HOST", "localhost"),
            port=os.getenv("DB_PORT", "5432"),
            database=os.getenv("DB_NAME", "airflow"),
            user=os.getenv("DB_USER", "airflow"),
            password=os.getenv("DB_PASSWORD", "airflow"),
        )
        df = pd.read_sql(sql, conn, params=params)
        conn.close()
        return df
    except Exception as e:
        st.error(f"Query failed: {e}")
        return pd.DataFrame()


# ============ SIDEBAR FILTERS ============
st.sidebar.header("🎯 Filters")

# Get available sectors from database
try:
    sectors_df = query_db(
        "SELECT DISTINCT sector FROM public_marts.mart_sector_performance ORDER BY sector"
    )
    sectors = sectors_df["sector"].tolist() if not sectors_df.empty else []
except Exception as e:
    st.error(f"Error loading sectors: {e}")
    sectors = []

# Sector selector
selected_sector = st.sidebar.selectbox(
    "Select Sector", options=sectors, index=0 if sectors else None
)

# Date range picker
col1, col2 = st.sidebar.columns(2)
with col1:
    start_date = st.date_input("Start Date", value=datetime.now() - timedelta(days=30))
with col2:
    end_date = st.date_input("End Date", value=datetime.now())

st.sidebar.markdown("---")
st.sidebar.markdown("**Data Source**: Postgres (mart_sector_performance)")

# ============ FETCH DATA ============
# FETCH DATA
try:
    # Query filtered data
    query = """
    SELECT
        date,
        sector,
        symbol_count,
        avg_daily_return,
        daily_volatility,
        return_1m,
        return_3m,
        return_1y,
        volatility_1y,
        sharpe_ratio_1y,
        ytd_return
    FROM public_marts.mart_sector_performance
    WHERE sector = %s
        AND date >= %s
        AND date <= %s
    ORDER BY date DESC
    """

    df = query_db(query, params=(selected_sector, start_date, end_date))

    if df.empty:
        st.warning(
            f"No data available for {selected_sector} in the selected date range"
        )
    else:
        # Get latest row for metric cards
        latest = df.iloc[0]

        # ============ METRIC CARDS ============
        st.header(f"📈 {selected_sector} Performance")

        col1, col2, col3, col4 = st.columns(4)

        with col1:
            st.metric(
                label="Sharpe Ratio (1Y)",
                value=(
                    f"{latest['sharpe_ratio_1y']:.2f}"
                    if pd.notna(latest["sharpe_ratio_1y"])
                    else "N/A"
                ),
                help="Risk-adjusted return (higher is better)",
            )

        with col2:
            st.metric(
                label="Volatility (1Y)",
                value=(
                    f"{latest['volatility_1y']:.4f}"
                    if pd.notna(latest["volatility_1y"])
                    else "N/A"
                ),
                help="Standard deviation of returns",
            )

        with col3:
            st.metric(
                label="Return (1Y)",
                value=(
                    f"{latest['return_1y']:.2%}"
                    if pd.notna(latest["return_1y"])
                    else "N/A"
                ),
                help="1-year rolling return",
            )

        with col4:
            st.metric(
                label="YTD Return",
                value=(
                    f"{latest['ytd_return']:.2%}"
                    if pd.notna(latest["ytd_return"])
                    else "N/A"
                ),
                help="Year-to-date return",
            )

        # ============ DATA TABLE ============
        st.header("📋 Daily Data")
        st.dataframe(
            df.rename(
                columns={
                    "date": "Date",
                    "sector": "Sector",
                    "symbol_count": "Symbols",
                    "avg_daily_return": "Avg Daily Return",
                    "daily_volatility": "Daily Vol",
                    "return_1m": "1M Return",
                    "return_3m": "3M Return",
                    "return_1y": "1Y Return",
                    "volatility_1y": "1Y Vol",
                    "sharpe_ratio_1y": "Sharpe (1Y)",
                    "ytd_return": "YTD Return",
                }
            ),
            use_container_width=True,
        )

except Exception as e:
    st.error(f"Database Error: {e}")
    st.write("Make sure Postgres is running and mart_sector_performance table exists")
