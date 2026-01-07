from sectoral import cli


def test_cli_main_smoke() -> None:
    """
    Smoke test: running the CLI entrypoint should succeed (exit code 0).

    This does not hit real APIs; if needed you can later patch
    ingestion to use a tiny, local dataset.
    """
    exit_code = cli.main()
    assert exit_code == 0
