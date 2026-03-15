{{ config(materialized='table') }}

with stock_prices as (
    select *
    from {{ ref('stg_stock_prices') }}
),

sector_mapping as (
    select *
    from {{ ref('stg_sector_data') }}
),

with_sectors as (
    select
        sp.symbol,
        sp.ts,
        sp.close,
        sp.volume,
        sm.sector
    from stock_prices sp
    left join sector_mapping sm on sp.symbol = sm.symbol
    where sm.sector is not null
),

with_daily_returns as (
    select
        symbol,
        sector,
        ts,
        close,
        volume,
        {{ calculate_daily_return('close') }} as daily_return
    from with_sectors
),

sector_aggregates as (
    select
        sector,
        ts,
        count(distinct symbol) as symbol_count,
        avg(daily_return) as avg_daily_return,
        approx_quantiles(daily_return, 100)[OFFSET(50)] as median_daily_return,
        stddev(daily_return) as daily_volatility,
        sum(volume) as total_volume,
        sum(close * volume) / sum(volume) as weighted_avg_price
    from with_daily_returns
    where daily_return is not null
    group by sector, ts
)

select *
from sector_aggregates
