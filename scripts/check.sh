#!/usr/bin/env bash
set -euo pipefail

uv run pre-commit run --all-files
uv run pytest --cov=src/sectoral --cov-report=term-missing
