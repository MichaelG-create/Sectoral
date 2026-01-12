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
        lower(symbol)                          as symbol,
        cast(ts as timestamp)                  as ts,
        cast(open  as numeric(18, 6))          as open,
        cast(high  as numeric(18, 6))          as high,
        cast(low   as numeric(18, 6))          as low,
        cast(close as numeric(18, 6))          as close,
        cast(volume as bigint)                 as volume
    from raw
    where close is not null

)

select *
from cleaned
