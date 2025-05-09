WITH txn_filtered AS (               -- 1. keep only BTC “BUY” txns and attach price + region
    SELECT
        bt.member_id,
        bm.region,
        bt.txn_date,
        CAST(substr(bt.txn_date, -4) AS INTEGER)      AS year,
        bt.quantity,
        bp.price,
        bt.quantity * bp.price                        AS amount_spent
    FROM bitcoin_transactions        AS bt
    JOIN bitcoin_members             AS bm  ON bt.member_id = bm.member_id
    JOIN bitcoin_prices              AS bp
         ON  bt.ticker      = bp.ticker            -- same coin (BTC)
         AND bt.txn_date    = bp.market_date       -- same calendar day
    WHERE bt.ticker   = 'BTC'
      AND bt.txn_type = 'BUY'
),
yearly_region AS (                  -- 2. yearly totals & average purchase price
    SELECT
        region,
        year,
        SUM(amount_spent)                     AS total_spent,
        SUM(quantity)                         AS total_qty,
        SUM(amount_spent) / SUM(quantity)     AS avg_purchase_price
    FROM txn_filtered
    GROUP BY region, year
),
first_year AS (                     -- 3. earliest year with purchases for every region
    SELECT region, MIN(year) AS first_year
    FROM yearly_region
    GROUP BY region
),
stats_excl_first AS (               -- 4. drop each region’s first‐year results
    SELECT yr.*
    FROM yearly_region  AS yr
    JOIN first_year     AS fy USING (region)
    WHERE yr.year > fy.first_year
),
rank_and_lag AS (                   -- 5. rank within year & pull prior year’s price
    SELECT
        year,
        region,
        ROUND(avg_purchase_price,4)                         AS avg_purchase_price,
        RANK() OVER (PARTITION BY year
                     ORDER BY avg_purchase_price DESC)      AS region_rank,
        LAG(avg_purchase_price) OVER (PARTITION BY region
                                      ORDER BY year)        AS prev_price
    FROM stats_excl_first
)
SELECT
    year,
    region,
    avg_purchase_price,
    region_rank,
    ROUND(
        CASE WHEN prev_price IS NULL OR prev_price = 0
             THEN NULL
             ELSE 100.0 * (avg_purchase_price - prev_price) / prev_price
        END
    ,4) AS pct_change_vs_prev_year
FROM   rank_and_lag
ORDER BY year,
         region_rank,
         region;