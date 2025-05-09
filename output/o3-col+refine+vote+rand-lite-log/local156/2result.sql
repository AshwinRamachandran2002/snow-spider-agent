WITH btc_region_year AS (
    /* 1.  Total cost (USD) and quantity (BTC) bought each year by region            */
    SELECT
        bm."region",
        SUBSTR(bt."txn_date", 7, 4)                     AS "calendar_year",
        SUM(bt."quantity" * bp."price")                AS "total_cost_usd",
        SUM(bt."quantity")                             AS "total_qty_btc"
    FROM "bitcoin_transactions"  AS bt
    JOIN "bitcoin_members"       AS bm ON bt."member_id" = bm."member_id"
    JOIN "bitcoin_prices"        AS bp ON bp."ticker"    = 'BTC'
                                      AND bp."market_date" = bt."txn_date"
    WHERE bt."txn_type" = 'BUY'
      AND bt."ticker"   = 'BTC'         -- keep only BTC purchases
    GROUP BY bm."region", SUBSTR(bt."txn_date", 7, 4)
),
region_year_avgs AS (
    /* 2.  Average purchase price and year-on-year helpers                           */
    SELECT
        "region",
        "calendar_year",
        "total_cost_usd",
        "total_qty_btc",
        "total_cost_usd" * 1.0 / "total_qty_btc"                AS "avg_price_btc",
        ROW_NUMBER() OVER (PARTITION BY "region"
                           ORDER BY CAST("calendar_year" AS INTEGER))             AS rn,
        LAG("total_cost_usd" * 1.0 / "total_qty_btc")
             OVER (PARTITION BY "region"
                   ORDER BY CAST("calendar_year" AS INTEGER))                     AS prior_avg
    FROM btc_region_year
),
filtered AS (
    /* 3.  Remove the first year for every region                                    */
    SELECT *
    FROM region_year_avgs
    WHERE rn > 1
)
SELECT
    "calendar_year",
    "region",
    ROUND("avg_price_btc", 4)                                                             AS "avg_price_btc",
    RANK() OVER (PARTITION BY "calendar_year"
                 ORDER BY "avg_price_btc" DESC)                                           AS "region_rank",
    ROUND( (("avg_price_btc" - "prior_avg") / "prior_avg") * 100.0 , 2)                   AS "pct_change_vs_prev_year"
FROM filtered
ORDER BY CAST("calendar_year" AS INTEGER),
         "region_rank";