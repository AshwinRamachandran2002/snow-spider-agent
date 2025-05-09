WITH txn_price AS (
    /* 1. add price to each BTC buy transaction and map to customer region */
    SELECT
        bm."region",
        CAST(substr(bt."txn_date", 7, 4) AS INTEGER)      AS year,
        bt."quantity",
        bp."price"
    FROM "bitcoin_transactions" bt
    JOIN "bitcoin_members"      bm ON bt."member_id" = bm."member_id"
    JOIN "bitcoin_prices"       bp
         ON  bt."ticker"      = bp."ticker"
         AND bt."txn_date"    = bp."market_date"
    WHERE bt."ticker"   = 'BTC'
      AND bt."txn_type" = 'BUY'
),
region_year_stats AS (
    /* 2. yearly totals and average purchase price (cost per Bitcoin) */
    SELECT
        region,
        year,
        SUM(quantity * price)                   AS total_spent_usd,
        SUM(quantity)                           AS total_btc,
        SUM(quantity * price) / SUM(quantity)   AS avg_purchase_price
    FROM txn_price
    GROUP BY region, year
),
with_change AS (
    /* 3. attach sequence of years per region and previous‑year value */
    SELECT
        region,
        year,
        avg_purchase_price,
        DENSE_RANK() OVER (PARTITION BY region ORDER BY year)            AS yr_seq,
        LAG(avg_purchase_price) OVER (PARTITION BY region ORDER BY year) AS prev_avg_price
    FROM region_year_stats
),
filtered AS (
    /* 4. drop the first recorded year for each region */
    SELECT *
    FROM with_change
    WHERE yr_seq > 1
)
SELECT
    year,
    region,
    ROUND(avg_purchase_price, 4)                                       AS avg_purchase_price,
    RANK() OVER (PARTITION BY year ORDER BY avg_purchase_price DESC)   AS region_rank_for_year,
    ROUND(
        (avg_purchase_price - prev_avg_price) * 100.0 / prev_avg_price,
        4
    )                                                                  AS pct_change_vs_prev_year
FROM filtered
ORDER BY year,
         region_rank_for_year,
         region;