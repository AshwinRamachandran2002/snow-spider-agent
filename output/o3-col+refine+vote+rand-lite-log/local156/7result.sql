WITH yearly_totals AS (   -- 1. yearly totals per region
    SELECT
        bm."region"                                    AS region,
        CAST(substr(bt."txn_date", -4) AS INTEGER)     AS calendar_year,
        SUM(bt."quantity")                             AS qty_bought,
        SUM(bt."quantity" * bp."price")                AS usd_spent
    FROM   "bitcoin_transactions"  AS bt
    JOIN   "bitcoin_members"       AS bm  ON bt."member_id" = bm."member_id"
    JOIN   "bitcoin_prices"        AS bp  ON bt."txn_date"  = bp."market_date"
    WHERE  bt."ticker"   = 'BTC'
      AND  bt."txn_type" = 'BUY'
      AND  bp."ticker"   = 'BTC'
    GROUP BY bm."region",
             CAST(substr(bt."txn_date", -4) AS INTEGER)
),
avg_px AS (              -- 2. average cost & position in each region’s timeline
    SELECT
        region,
        calendar_year,
        ROUND(usd_spent / qty_bought, 2)               AS avg_buy_px,
        ROW_NUMBER() OVER (PARTITION BY region
                           ORDER BY calendar_year)     AS rn
    FROM yearly_totals
),
filtered AS (            -- 3. drop the first year for every region
    SELECT
        region,
        calendar_year,
        avg_buy_px,
        LAG(avg_buy_px) OVER (PARTITION BY region
                              ORDER BY calendar_year)  AS prev_avg
    FROM   avg_px
    WHERE  rn > 1
)
-- 4. final result: YoY % change and ranking per calendar year
SELECT
    calendar_year,
    region,
    avg_buy_px,
    ROUND(
        100.0 * (avg_buy_px - prev_avg) / prev_avg,
        2
    )                                                   AS pct_change_vs_prev_year,
    RANK() OVER (PARTITION BY calendar_year
                 ORDER BY avg_buy_px DESC)              AS region_rank
FROM   filtered
ORDER BY calendar_year,
         region_rank;