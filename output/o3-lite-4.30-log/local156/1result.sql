WITH btc_price AS (
    -- daily BTC price (average if duplicates exist)
    SELECT "market_date",
           AVG("price") AS "price"
    FROM   "bitcoin_prices"
    WHERE  "ticker" = 'BTC'
    GROUP  BY "market_date"
),
btc_txn AS (
    -- every BTC BUY augmented with region and price
    SELECT bm."region",
           CAST(substr(bt."txn_date", 7, 4) AS INTEGER) AS "year",
           bt."quantity",
           bp."price"
    FROM   "bitcoin_transactions" bt
    JOIN   "bitcoin_members" bm ON bt."member_id" = bm."member_id"
    JOIN   btc_price bp        ON bt."txn_date"   = bp."market_date"
    WHERE  bt."ticker"   = 'BTC'
      AND  bt."txn_type" = 'BUY'
),
yearly AS (
    -- annual average purchase price per region
    SELECT  "region",
            "year",
            SUM("quantity")                     AS total_qty,
            SUM("quantity" * "price")           AS total_spent,
            SUM("quantity" * "price") * 1.0 /
            SUM("quantity")                     AS avg_price_usd
    FROM    btc_txn
    GROUP   BY "region", "year"
),
lagged AS (
    -- add previous‑year average and row number per region
    SELECT  region,
            year,
            avg_price_usd,
            ROW_NUMBER()  OVER (PARTITION BY region ORDER BY year)       AS rn,
            LAG(avg_price_usd) OVER (PARTITION BY region ORDER BY year)  AS prev_avg
    FROM    yearly
),
filtered AS (
    -- drop first year per region
    SELECT *
    FROM   lagged
    WHERE  rn > 1
)
SELECT  year,
        region,
        ROUND(avg_price_usd, 4)                                         AS avg_purchase_price_usd,
        RANK() OVER (PARTITION BY year ORDER BY avg_price_usd DESC)     AS rank_within_year,
        ROUND((avg_price_usd - prev_avg) * 100.0 / prev_avg, 4)        AS pct_change_vs_prev_year
FROM    filtered
ORDER BY year,
         rank_within_year,
         region;