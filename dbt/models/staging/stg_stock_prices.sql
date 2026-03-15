{{ config(materialized='view') }}

with raw as (

    select
        symbol,
        ts,
        open,
        high,
        low,
        close,
        volume
    from {{ source('sectoral_raw', 'raw_stock_prices') }}

),

cleaned as (

    select
        lower(symbol)            as symbol,
        cast(ts as timestamp)    as ts,
        cast(open  as numeric)   as open,
        cast(high  as numeric)   as high,
        cast(low   as numeric)   as low,
        cast(close as numeric)   as close,
        cast(volume as int64)    as volume
    from raw
    where close is not null

)

select *
from cleaned
