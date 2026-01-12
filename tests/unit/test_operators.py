from __future__ import annotations

from unittest.mock import MagicMock, patch

import pandas as pd
import pytest

from sectoral.operators import SectoralIngestionOperator, SectoralTransformOperator


@pytest.fixture
def mock_config():
    """Mock SectoralConfig with minimal sectors."""
    return {
        "sectors": {
            "Technology": ["AAPL", "MSFT"],
            "Finance": ["JPM"],
        },
        "days_back": 30,
    }


@pytest.fixture
def mock_raw_data():
    """Mock raw market data (dict of DataFrames)."""
    dates = pd.date_range("2024-01-01", periods=10, freq="D")
    return {
        "AAPL": pd.DataFrame({"Close": range(100, 110)}, index=dates),
        "MSFT": pd.DataFrame({"Close": range(200, 210)}, index=dates),
        "JPM": pd.DataFrame({"Close": range(150, 160)}, index=dates),
    }


def test_ingestion_operator_writes_csv_files(tmp_path, mock_config, mock_raw_data):
    """Test SectoralIngestionOperator writes CSV files for each symbol."""

    config_path = tmp_path / "test_config.yaml"
    output_dir = tmp_path / "raw"

    # Create a minimal YAML config file
    import yaml

    with open(config_path, "w") as f:
        yaml.dump(
            {"sectors": mock_config["sectors"], "analysis_window": {"days_back": 30}}, f
        )

    operator = SectoralIngestionOperator(
        task_id="test_ingest",
        config_path=str(config_path),
        output_dir=str(output_dir),
    )

    # Mock the ingestion function to return fake data
    with patch("sectoral.operators.ingest_data", return_value=mock_raw_data):
        context = MagicMock()
        result = operator.execute(context)

    # Verify return value
    assert result["num_symbols"] == 3
    assert set(result["symbols_ingested"]) == {"AAPL", "MSFT", "JPM"}
    assert "start_date" in result
    assert "end_date" in result

    # Verify CSV files were written
    assert (output_dir / "AAPL.csv").exists()
    assert (output_dir / "MSFT.csv").exists()
    assert (output_dir / "JPM.csv").exists()

    # Verify content of one file
    df = pd.read_csv(output_dir / "AAPL.csv", index_col=0, parse_dates=True)
    assert len(df) == 10
    assert "Close" in df.columns


def test_ingestion_operator_handles_empty_data(tmp_path, mock_config):
    """Test SectoralIngestionOperator handles empty ingestion gracefully."""

    config_path = tmp_path / "test_config.yaml"
    output_dir = tmp_path / "raw"

    import yaml

    with open(config_path, "w") as f:
        yaml.dump(
            {"sectors": mock_config["sectors"], "analysis_window": {"days_back": 30}}, f
        )

    operator = SectoralIngestionOperator(
        task_id="test_ingest_empty",
        config_path=str(config_path),
        output_dir=str(output_dir),
    )

    # Mock ingestion to return empty dict
    with patch("sectoral.operators.ingest_data", return_value={}):
        context = MagicMock()
        result = operator.execute(context)

    assert result["num_symbols"] == 0
    assert result["symbols_ingested"] == []


def test_transform_operator_reads_and_transforms(tmp_path, mock_config, mock_raw_data):
    """Test SectoralTransformOperator reads raw data and exports results."""

    config_path = tmp_path / "test_config.yaml"
    input_dir = tmp_path / "raw"
    output_dir = tmp_path / "outputs"

    # Setup: write config and raw CSV files
    import yaml

    with open(config_path, "w") as f:
        yaml.dump(
            {"sectors": mock_config["sectors"], "analysis_window": {"days_back": 30}}, f
        )

    input_dir.mkdir()
    for symbol, df in mock_raw_data.items():
        df.to_csv(input_dir / f"{symbol}.csv")

    operator = SectoralTransformOperator(
        task_id="test_transform",
        config_path=str(config_path),
        input_dir=str(input_dir),
        output_dir=str(output_dir),
    )

    context = MagicMock()
    result = operator.execute(context)

    # Verify return value
    assert result["num_symbols"] == 3
    assert result["num_sectors"] == 2
    assert result["insights_count"] > 0

    # Verify export files were created
    assert (output_dir / "symbol_metrics.csv").exists()
    assert (output_dir / "sector_aggregates.csv").exists()
    assert (output_dir / "sector_correlation.csv").exists()

    # Verify sector aggregates content
    sector_agg = pd.read_csv(output_dir / "sector_aggregates.csv")
    assert len(sector_agg) == 2
    assert set(sector_agg["Sector"]) == {"Technology", "Finance"}
    assert "Cumulative_Return" in sector_agg.columns
    assert "Volatility" in sector_agg.columns
    assert "Sharpe_Ratio" in sector_agg.columns


def test_transform_operator_handles_missing_files(tmp_path, mock_config):
    """Test SectoralTransformOperator handles missing raw files gracefully."""

    config_path = tmp_path / "test_config.yaml"
    input_dir = tmp_path / "raw"
    output_dir = tmp_path / "outputs"

    import yaml

    with open(config_path, "w") as f:
        yaml.dump(
            {"sectors": mock_config["sectors"], "analysis_window": {"days_back": 30}}, f
        )

    input_dir.mkdir()
    # Don't write any CSV files - simulate missing data

    operator = SectoralTransformOperator(
        task_id="test_transform_missing",
        config_path=str(config_path),
        input_dir=str(input_dir),
        output_dir=str(output_dir),
    )

    context = MagicMock()
    result = operator.execute(context)

    # Should complete but with zero symbols
    assert result["num_symbols"] == 0


def test_transform_operator_read_raw_data_helper(tmp_path, mock_config, mock_raw_data):
    """Test the _read_raw_data helper method directly."""

    config_path = tmp_path / "test_config.yaml"
    input_dir = tmp_path / "raw"

    import yaml

    with open(config_path, "w") as f:
        yaml.dump(
            {"sectors": mock_config["sectors"], "analysis_window": {"days_back": 30}}, f
        )

    from sectoral.config import SectoralConfig

    cfg = SectoralConfig.from_yaml(config_path)

    # Write raw CSV files
    input_dir.mkdir()
    for symbol, df in mock_raw_data.items():
        df.to_csv(input_dir / f"{symbol}.csv")

    operator = SectoralTransformOperator(
        task_id="test_helper",
        config_path=str(config_path),
        input_dir=str(input_dir),
        output_dir=str(tmp_path / "outputs"),
    )

    raw = operator._read_raw_data(cfg)

    assert len(raw) == 3
    assert "AAPL" in raw
    assert "MSFT" in raw
    assert "JPM" in raw
    assert len(raw["AAPL"]) == 10
