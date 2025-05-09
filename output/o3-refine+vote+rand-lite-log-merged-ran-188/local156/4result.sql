WITH purchase_tx AS (            -- 1. yearly spend & qty bought
    SELECT
        bm.region,
        CAST(SUBSTR(bt."txn_date", 7, 4) AS INTEGER)      AS txn_year,
        SUM(bt.quantity * bp.price)                       AS total_spent,
        SUM(bt.quantity)                                  AS total_qty
    FROM   "bitcoin_transactions"  bt
    JOIN   "bitcoin_members"       bm  ON bm.member_id = bt.member_id
    JOIN   "bitcoin_prices"        bp  ON bp.ticker = bt.ticker
                                       AND bp.market_date = bt."txn_date"
    WHERE  bt.ticker   = 'BTC'
      AND  bt.txn_type = 'BUY'
    GROUP  BY bm.region, txn_year
),
first_year_per_region AS (        -- 2. first year to be excluded
    SELECT region,
           MIN(txn_year) AS first_year
    FROM   purchase_tx
    GROUP  BY region
),
avg_price AS (                    -- 3. average purchase price per BTC
    SELECT
        region,
        txn_year,
        (total_spent * 1.0) / total_qty AS avg_price
    FROM   purchase_tx
),
avg_price_with_lag AS (           -- 4. add previous‑year price for % change
    SELECT
        a.*,
        fy.first_year,
        LAG(a.avg_price) OVER (PARTITION BY a.region ORDER BY a.txn_year) AS prev_avg_price
    FROM   avg_price a
    JOIN   first_year_per_region fy
           ON a.region = fy.region
)
SELECT
    region,
    txn_year                                            AS year,
    ROUND(avg_price, 4)                                 AS avg_purchase_price,
    RANK() OVER (PARTITION BY txn_year
                 ORDER BY avg_price DESC)               AS region_rank,
    CASE
        WHEN prev_avg_price IS NULL THEN NULL
        ELSE ROUND( (avg_price - prev_avg_price) * 100.0 / prev_avg_price , 4)
    END                                                 AS pct_change_vs_prev_year
FROM   avg_price_with_lag
WHERE  txn_year > first_year                            -- exclude each region’s first year
ORDER  BY year,
          region_rank,
          region;