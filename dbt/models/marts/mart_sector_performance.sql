{{ config(materialized='table') }}

with sector_agg as (
    select *
    from {{ ref('int_sector_aggregates') }}
),

with_cumulative_return as (
    select
        sector,
        ts,
        symbol_count,
        avg_daily_return,
        median_daily_return,
        daily_volatility,
        total_volume,
        weighted_avg_price,
        -- cumulative return from first date to current date
        exp(sum(ln(1 + avg_daily_return)) over (
            partition by sector
            order by ts
            rows between unbounded preceding and current row
        )) - 1 as cum_return_from_inception,
        -- YTD cumulative return
        exp(sum(ln(1 + avg_daily_return)) over (
            partition by sector, date_trunc('year', ts)
            order by ts
            rows between unbounded preceding and current row
        )) - 1 as ytd_return
    from sector_agg
),

with_rolling_metrics as (
    select
        sector,
        ts,
        symbol_count,
        avg_daily_return,
        median_daily_return,
        daily_volatility,
        total_volume,
        weighted_avg_price,
        cum_return_from_inception,
        ytd_return,
        -- rolling 1-month return (21 trading days)
        exp(sum(ln(1 + avg_daily_return)) over (
            partition by sector
            order by ts
            rows between 20 preceding and current row
        )) - 1 as return_1m,
        -- rolling 3-month return (63 trading days)
        exp(sum(ln(1 + avg_daily_return)) over (
            partition by sector
            order by ts
            rows between 62 preceding and current row
        )) - 1 as return_3m,
        -- rolling 1-year return (252 trading days)
        exp(sum(ln(1 + avg_daily_return)) over (
            partition by sector
            order by ts
            rows between 251 preceding and current row
        )) - 1 as return_1y,
        -- rolling 252-day volatility
        stddev(avg_daily_return) over (
            partition by sector
            order by ts
            rows between 251 preceding and current row
        ) as volatility_1y
    from with_cumulative_return
),

with_sharpe_ratio as (
    select
        sector,
        ts,
        symbol_count,
        avg_daily_return,
        median_daily_return,
        daily_volatility,
        total_volume,
        weighted_avg_price,
        cum_return_from_inception,
        ytd_return,
        return_1m,
        return_3m,
        return_1y,
        volatility_1y,
        -- Sharpe ratio (252 trading days per year, 1.5% annual risk-free rate = 0.015)
        case
            when volatility_1y > 0 then (return_1y - 0.015) / volatility_1y
            else null
        end as sharpe_ratio_1y,
        -- current rank by 1y return
        row_number() over (
            partition by ts
            order by return_1y desc nulls last
        ) as sector_rank_by_return_1y
    from with_rolling_metrics
)

select
    sector,
    ts,
    cast(ts as date) as date,
    symbol_count,
    round(avg_daily_return::numeric, 6) as avg_daily_return,
    round(median_daily_return::numeric, 6) as median_daily_return,
    round(daily_volatility::numeric, 6) as daily_volatility,
    total_volume,
    round(weighted_avg_price::numeric, 2) as weighted_avg_price,
    round(cum_return_from_inception::numeric, 4) as cum_return_from_inception,
    round(ytd_return::numeric, 4) as ytd_return,
    round(return_1m::numeric, 4) as return_1m,
    round(return_3m::numeric, 4) as return_3m,
    round(return_1y::numeric, 4) as return_1y,
    round(volatility_1y::numeric, 4) as volatility_1y,
    round(sharpe_ratio_1y::numeric, 4) as sharpe_ratio_1y,
    sector_rank_by_return_1y
from with_sharpe_ratio
order by ts desc, sector
