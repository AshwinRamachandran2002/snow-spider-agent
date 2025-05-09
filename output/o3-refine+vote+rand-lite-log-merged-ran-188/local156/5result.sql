-- annual average BTC purchase price by region,
-- ranked by year, with YoY % change (first region‑year per
-- region is excluded from the analysis)

WITH buy_txns AS (            -- 1. all BTC BUY transactions
    SELECT
        bt.member_id,
        bt.ticker,
        bt.txn_date,
        CAST(substr(bt.txn_date, 7, 4) AS INTEGER) AS txn_year,
        bt.quantity
    FROM bitcoin_transactions AS bt
    WHERE UPPER(bt.txn_type) = 'BUY'
      AND UPPER(bt.ticker)  = 'BTC'
),

txns_with_price AS (          -- 2. attach region + daily USD price
    SELECT
        b.member_id,
        bm.region,
        b.txn_year,
        b.quantity,
        bp.price,
        b.quantity * bp.price AS amount_spent
    FROM buy_txns         AS b
    JOIN bitcoin_members  AS bm ON bm.member_id = b.member_id
    JOIN bitcoin_prices   AS bp
         ON bp.ticker      = b.ticker
        AND bp.market_date = b.txn_date          -- same dd‑mm‑yyyy text
),

region_year_stats AS (        -- 3. yearly totals per region
    SELECT
        region,
        txn_year  AS year,
        SUM(amount_spent)         AS total_spent,
        SUM(quantity)             AS total_qty,
        SUM(amount_spent) / SUM(quantity) AS avg_price
    FROM txns_with_price
    GROUP BY region, year
),

region_year_filtered AS (     -- 4. drop each region’s first year
    SELECT r.*
    FROM region_year_stats r
    JOIN (
        SELECT region, MIN(year) AS first_year
        FROM region_year_stats
        GROUP BY region
    ) f ON f.region = r.region
    WHERE r.year > f.first_year
),

region_year_ranked AS (       -- 5. add rank & YoY % change
    SELECT
        region,
        year,
        avg_price,
        RANK() OVER (PARTITION BY year ORDER BY avg_price DESC) AS region_rank,
        ROUND(
            (avg_price - LAG(avg_price) OVER (PARTITION BY region ORDER BY year))
            * 100.0
            / LAG(avg_price) OVER (PARTITION BY region ORDER BY year),
            4
        ) AS pct_change
    FROM region_year_filtered
)

SELECT
    year,
    region,
    ROUND(avg_price, 4)     AS avg_purchase_price,
    region_rank,
    pct_change              AS annual_pct_change
FROM region_year_ranked
ORDER BY year, region_rank, region;