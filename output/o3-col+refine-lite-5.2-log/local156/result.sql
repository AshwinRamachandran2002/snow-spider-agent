WITH btc_txn_pricing AS (
    /* Attach daily BTC market prices to all BUY transactions */
    SELECT
        bm."region",
        CAST(substr(bt."txn_date", 7, 4) AS INTEGER)        AS "calendar_year",
        (bt."quantity" * bp."price")                        AS "spend",
        bt."quantity"                                       AS "qty"
    FROM   "bitcoin_transactions"  AS bt
    JOIN   "bitcoin_members"       AS bm  ON bm."member_id"  = bt."member_id"
    JOIN   "bitcoin_prices"        AS bp  ON bp."ticker"     = bt."ticker"
                                          AND bp."market_date" = bt."txn_date"
    WHERE  bt."ticker"   = 'BTC'
      AND  bt."txn_type" = 'BUY'
),
region_year_totals AS (
    /* Annual totals and average purchase price (USD/BTC) */
    SELECT
        "region",
        "calendar_year",
        SUM("spend")                               AS "total_spend",
        SUM("qty")                                 AS "total_qty",
        SUM("spend") * 1.0 / SUM("qty")            AS "avg_price"
    FROM   btc_txn_pricing
    GROUP BY "region", "calendar_year"
),
exclude_first_year AS (
    /* Remove each region’s first purchase year */
    SELECT ryt.*
    FROM   region_year_totals AS ryt
    JOIN  (
        SELECT "region", MIN("calendar_year") AS "first_year"
        FROM   region_year_totals
        GROUP BY "region"
    ) AS rf
      ON ryt."region" = rf."region"
    WHERE ryt."calendar_year" > rf."first_year"
),
rank_and_change AS (
    /* Rank regions per year and compute YoY % change */
    SELECT
        *,
        RANK() OVER (PARTITION BY "calendar_year"
                     ORDER BY "avg_price" DESC)          AS "price_rank",
        LAG("avg_price") OVER (PARTITION BY "region"
                               ORDER BY "calendar_year") AS "prev_avg_price"
    FROM   exclude_first_year
)
SELECT
    "region",
    "calendar_year",
    ROUND("avg_price", 4)                                           AS "avg_price_usd_per_btc",
    "price_rank",
    ROUND((("avg_price" - "prev_avg_price") * 100.0) /
          "prev_avg_price", 4)                                      AS "pct_change_vs_prev_year"
FROM   rank_and_change
ORDER BY "calendar_year", "price_rank";