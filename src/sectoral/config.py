from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Any

import yaml  # ensure pyyaml is in your dependencies


CONFIG_PATH = Path("config/sectoral.yaml")


@dataclass
class SectoralConfig:
    sectors: Dict[str, List[str]]
    days_back: int

    @classmethod
    def from_yaml(cls, path: Path = CONFIG_PATH) -> "SectoralConfig":
        with path.open("r", encoding="utf-8") as f:
            raw: Dict[str, Any] = yaml.safe_load(f) or {}

        sectors = raw.get("sectors", {})
        window = raw.get("analysis_window", {}) or {}
        days_back = int(window.get("days_back", 365))

        return cls(sectors=sectors, days_back=days_back)


def resolve_dates(days_back: int) -> tuple[str, str]:
    start = (datetime.now() - timedelta(days=days_back)).strftime("%Y-%m-%d")
    end = datetime.now().strftime("%Y-%m-%d")
    return start, end
