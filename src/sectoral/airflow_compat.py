from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from airflow.models import BaseOperator
else:
    try:
        from airflow.models import BaseOperator  # type: ignore[import]
    except ModuleNotFoundError:

        class BaseOperator:  # minimal stub for tests
            def __init__(self, *args, **kwargs):
                pass

            def execute(self, context):
                raise NotImplementedError
