{% macro calculate_daily_return(price_column) %}
    ({{ price_column }} - lag({{ price_column }}) over (partition by symbol order by ts))
    / lag({{ price_column }}) over (partition by symbol order by ts)
{% endmacro %}
