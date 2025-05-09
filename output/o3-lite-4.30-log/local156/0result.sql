WITH yearly AS (
    SELECT
        bm."region" AS region,
        CAST(SUBSTR(bt."txn_date", -4) AS INTEGER) AS year,
        SUM(bt."quantity" * bp."price") / SUM(bt."quantity") AS avg_price
    FROM "bitcoin_transactions" bt
    JOIN "bitcoin_members"  bm ON bt."member_id" = bm."member_id"
    JOIN "bitcoin_prices"   bp ON bt."ticker" = bp."ticker"
                              AND bt."txn_date" = bp."market_date"
    WHERE bt."ticker" = 'BTC'
      AND bt."txn_type" = 'BUY'
    GROUP BY bm."region", CAST(SUBSTR(bt."txn_date", -4) AS INTEGER)
),
with_prev AS (
    SELECT
        region,
        year,
        avg_price,
        LAG(avg_price) OVER (PARTITION BY region ORDER BY year) AS prev_avg
    FROM yearly
),
ranked AS (
    SELECT
        year,
        region,
        avg_price,
        RANK() OVER (PARTITION BY year ORDER BY avg_price DESC) AS rank_within_year,
        prev_avg
    FROM with_prev
)
SELECT
    year,
    region,
    ROUND(avg_price, 4) AS avg_purchase_price_usd,
    rank_within_year,
    ROUND((avg_price - prev_avg) * 100.0 / prev_avg, 4) AS pct_change_vs_prev_year
FROM ranked
WHERE prev_avg IS NOT NULL
ORDER BY year, rank_within_year, region;