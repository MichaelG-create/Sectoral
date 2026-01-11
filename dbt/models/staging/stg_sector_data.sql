{{ config(materialized='view') }}

with raw as (

    select
        symbol,
        sector
    from {{ source('sectoral_raw', 'raw_sector_data') }}

),

cleaned as (

    select
        lower(symbol)      as symbol,
        initcap(sector)    as sector
    from raw
    where sector is not null

)

select *
from cleaned
