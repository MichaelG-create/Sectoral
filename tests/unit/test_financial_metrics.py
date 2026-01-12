from __future__ import annotations

import numpy as np
import pandas as pd

from sectoral.analytics import compute_correlations
from sectoral.transforms import compute_symbol_metrics


def _make_price_series(prices: list[float]) -> pd.DataFrame:
    dates = pd.date_range("2024-01-01", periods=len(prices), freq="D")
    return pd.DataFrame({"Close": prices}, index=dates)


# tests/unit/test_financial_metrics.py


def test_daily_returns_simple_sequence() -> None:
    raw = {
        "AAA": _make_price_series([100, 110, 121]),
    }

    symbol_data = compute_symbol_metrics(raw)
    df = symbol_data["AAA"]

    expected = pd.Series([np.nan, 0.10, 0.10], index=df.index, name="Daily_Return")

    pd.testing.assert_series_equal(
        df["Daily_Return"],
        expected,
        check_names=True,
        check_exact=False,
        rtol=1e-10,
        atol=1e-10,
    )


def test_volatility_30d_matches_manual() -> None:
    # constant 1% return -> volatility should be ~0
    prices = [100 * (1.01) ** i for i in range(60)]
    raw = {"AAA": _make_price_series(prices)}

    symbol_data = compute_symbol_metrics(raw)
    df = symbol_data["AAA"]

    # After warmup, Volatility_30d should be extremely small
    vol_tail = df["Volatility_30d"].dropna().tail(5)
    assert (vol_tail < 1e-8).all()


def test_sharpe_ratio_positive_for_positive_returns() -> None:
    base = [100 * (1.002) ** i for i in range(252)]
    noise = np.random.normal(0, 0.1, size=len(base))
    prices = [p + n for p, n in zip(base, noise)]
    raw = {"AAA": _make_price_series(prices)}

    symbol_data = compute_symbol_metrics(raw)

    daily = symbol_data["AAA"]["Daily_Return"].dropna()
    mean = daily.mean() * 252
    vol = daily.std() * np.sqrt(252)
    sharpe = mean / vol

    assert sharpe > 0


def test_correlation_matrix_values() -> None:
    dates = pd.date_range("2024-01-01", periods=10, freq="D")
    s1 = pd.Series(np.linspace(0.0, 0.09, len(dates)), index=dates)
    s2 = s1 * 2
    s3 = pd.Series(np.random.RandomState(0).normal(0, 0.01, len(dates)), index=dates)

    sector_data = {
        "Tech": {"daily_returns": s1},
        "Finance": {"daily_returns": s2},
        "Energy": {"daily_returns": s3},
    }

    corr = compute_correlations(sector_data)

    assert np.isclose(corr.loc["Tech", "Finance"], 1.0, atol=1e-6)
    assert corr.loc["Tech", "Energy"] < 0.9
    assert corr.loc["Finance", "Energy"] < 0.9
