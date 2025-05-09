WITH region_year_stats AS (           /* 1.  yearly $ spent and qty bought for each region */
    SELECT
        bm.region                                   AS region,
        CAST(substr(bt.txn_date, 7, 4) AS INTEGER)  AS year,
        SUM(bt.quantity * bp.price)                 AS total_spent,
        SUM(bt.quantity)                            AS total_qty
    FROM   bitcoin_transactions  bt
    JOIN   bitcoin_members       bm  ON bm.member_id = bt.member_id
    JOIN   bitcoin_prices        bp  ON bp.ticker      = 'BTC'
                                    AND bp.ticker      = bt.ticker
                                    AND bp.market_date = bt.txn_date      -- same dd‑mm‑yyyy format
    WHERE  bt.ticker   = 'BTC'
      AND  UPPER(bt.txn_type) = 'BUY'                                   -- purchases only
    GROUP  BY bm.region, year
),

stats_with_avg AS (                  /* 2. average purchase price per BTC */
    SELECT
        region,
        year,
        total_spent,
        total_qty,
        total_spent / total_qty       AS avg_price
    FROM   region_year_stats
),

exclude_first_year AS (              /* 3. drop the first year observed for every region */
    SELECT *
    FROM  (
        SELECT
            s.*,
            ROW_NUMBER() OVER (PARTITION BY region ORDER BY year) AS rn
        FROM stats_with_avg s
    )
    WHERE rn > 1
),

ranked AS (                          /* 4. ranking & YoY percentage change */
    SELECT
        year,
        region,
        avg_price,
        DENSE_RANK() OVER (PARTITION BY year ORDER BY avg_price DESC)      AS region_rank,
        LAG(avg_price)  OVER (PARTITION BY region ORDER BY year)           AS prev_avg_price
    FROM   exclude_first_year
)

SELECT
    year,
    region,
    ROUND(avg_price, 4)                                                    AS avg_purchase_price,
    region_rank,
    ROUND( (avg_price - prev_avg_price) * 100.0 / prev_avg_price, 4)       AS pct_change_from_prev_year
FROM   ranked
ORDER  BY year, region_rank, region;