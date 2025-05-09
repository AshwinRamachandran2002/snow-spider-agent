WITH btc_purchases AS (
    /* 1.  All BTC BUY transactions with their USD out‑lay */
    SELECT
        bm.region,
        CAST(substr(bt.txn_date, length(bt.txn_date)-3, 4) AS INTEGER)    AS year,
        bt.quantity                                                      AS qty,
        bp.price                                                         AS px_usd,
        bt.quantity * bp.price                                           AS amt_spent
    FROM bitcoin_transactions  bt
    JOIN bitcoin_members       bm  ON bm.member_id = bt.member_id
    JOIN bitcoin_prices        bp  ON bp.ticker      = 'BTC'
                                   AND bp.market_date = bt.txn_date
    WHERE bt.ticker = 'BTC'
      AND UPPER(bt.txn_type) = 'BUY'
),
yearly_avg AS (
    /* 2.  Annual average purchase price per region                */
    SELECT
        region,
        year,
        SUM(amt_spent)                 AS total_spent,
        SUM(qty)                       AS total_qty,
        SUM(amt_spent)*1.0/SUM(qty)    AS avg_price
    FROM btc_purchases
    GROUP BY region, year
),
lagged AS (
    /* 3.  Bring in prior‑year average price and identify first year */
    SELECT
        y.*,
        LAG(avg_price) OVER (PARTITION BY region ORDER BY year)  AS prev_avg_price,
        MIN(year)     OVER (PARTITION BY region)                AS first_year
    FROM yearly_avg y
),
filtered AS (
    /* 4.  Exclude the first calendar year per region */
    SELECT *
    FROM lagged
    WHERE year > first_year
),
ranked AS (
    /* 5.  Rank regions within each year by average price */
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY year
                           ORDER BY avg_price DESC, region)     AS region_rank
    FROM filtered
)
SELECT
    year,
    region,
    ROUND(avg_price, 4)                                AS avg_purchase_price,
    region_rank,
    ROUND( (avg_price - prev_avg_price)
           * 100.0 / prev_avg_price, 4)                AS pct_change_vs_prev_year
FROM ranked
ORDER BY year, region_rank, region;