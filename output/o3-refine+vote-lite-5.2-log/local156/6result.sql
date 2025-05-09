WITH btc_purchases AS (
    /* 1. keep only BTC BUY transactions and attach member region + daily price */
    SELECT
        bm.region,
        bt.txn_date,
        CAST(substr(bt.txn_date, -4) AS INTEGER)  AS txn_year,
        bt.quantity,
        bp.price,
        bt.quantity * bp.price                    AS amount_spent
    FROM bitcoin_transactions  bt
    JOIN bitcoin_members       bm ON bm.member_id = bt.member_id
    JOIN bitcoin_prices        bp ON  bp.ticker      = bt.ticker
                                 AND bp.market_date  = bt.txn_date
    WHERE bt.ticker   = 'BTC'
      AND bt.txn_type = 'BUY'
),
yearly_avg_price AS (
    /* 2. total spend ÷ total qty for each region‑year */
    SELECT
        region,
        txn_year                                    AS year,
        SUM(amount_spent)              AS total_spent,
        SUM(quantity)                  AS total_qty,
        SUM(amount_spent)*1.0 /
        SUM(quantity)                  AS avg_price
    FROM btc_purchases
    GROUP BY region, year
),
flag_first_year AS (
    /* 3. label the first year per region and bring forward previous price */
    SELECT
        region,
        year,
        avg_price,
        ROW_NUMBER() OVER (PARTITION BY region ORDER BY year)               AS rn,
        LAG(avg_price) OVER (PARTITION BY region ORDER BY year)             AS prev_avg_price
    FROM yearly_avg_price
),
filtered AS (
    /* 4. exclude the very first year for each region */
    SELECT
        region,
        year,
        avg_price,
        prev_avg_price
    FROM flag_first_year
    WHERE rn > 1
),
pct_change AS (
    /* 5. percentage change vs previous year (for remaining rows) */
    SELECT
        region,
        year,
        avg_price,
        (avg_price - prev_avg_price) * 100.0 / prev_avg_price  AS pct_change
    FROM filtered
),
ranked AS (
    /* 6. rank regions by cost (higher price ⇒ rank 1) within each year */
    SELECT
        year,
        region,
        avg_price,
        DENSE_RANK() OVER (PARTITION BY year ORDER BY avg_price DESC) AS price_rank,
        pct_change
    FROM pct_change
)
SELECT
    year,
    region,
    ROUND(avg_price, 4)   AS avg_purchase_price,
    price_rank,
    ROUND(pct_change, 4)  AS pct_change_vs_prev_year
FROM ranked
ORDER BY year,
         price_rank,
         region;