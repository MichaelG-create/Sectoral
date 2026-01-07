from datetime import datetime, timedelta
from typing import Dict, List


DEFAULT_SECTORS: Dict[str, List[str]] = {
    "Technology": ["AAPL", "MSFT", "GOOGL", "NVDA"],
    "Healthcare": ["JNJ", "PFE", "UNH", "ABBV"],
    "Finance": ["JPM", "BAC", "WFC", "GS"],
    "Energy": ["XOM", "CVX", "COP", "SLB"],
    "Consumer": ["AMZN", "TSLA", "HD", "MCD"],
}


def resolve_dates(days_back: int = 365) -> tuple[str, str]:
    start = (datetime.now() - timedelta(days=days_back)).strftime("%Y-%m-%d")
    end = datetime.now().strftime("%Y-%m-%d")
    return start, end
