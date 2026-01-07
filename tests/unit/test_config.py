# tests/unit/test_config.py
from pathlib import Path

from sectoral.config import SectoralConfig

def test_sectoral_config_default_yaml() -> None:
    cfg = SectoralConfig.from_yaml(Path("config/sectoral.yaml"))
    assert "Technology" in cfg.sectors
    assert cfg.days_back > 0
