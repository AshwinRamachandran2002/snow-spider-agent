WITH btc_purchases AS (
    SELECT
        bm."region",
        CAST(substr(bt."txn_date", -4) AS INTEGER)                     AS "year",
        bt."quantity",
        bp."price",
        bt."quantity" * bp."price"                                     AS "amount_spent"
    FROM "bitcoin_transactions"  bt
    JOIN "bitcoin_members"       bm ON bt."member_id" = bm."member_id"
    JOIN "bitcoin_prices"        bp ON bt."ticker"    = bp."ticker"
                                   AND bt."txn_date"  = bp."market_date"
    WHERE bt."ticker" = 'BTC'
      AND bt."txn_type" = 'BUY'
),
region_year AS (
    SELECT
        "region",
        "year",
        SUM("amount_spent") / SUM("quantity")                          AS "avg_price"
    FROM btc_purchases
    GROUP BY "region", "year"
),
region_year_ex_first AS (
    SELECT ry.*
    FROM   region_year ry
    JOIN  (SELECT "region", MIN("year") AS first_year
           FROM region_year
           GROUP BY "region") fy
      ON ry."region" = fy."region"
    WHERE ry."year"  > fy.first_year
),
ranked AS (
    SELECT
        "year",
        "region",
        "avg_price",
        RANK() OVER (PARTITION BY "year"
                     ORDER BY "avg_price" DESC)                        AS "rank_within_year",
        LAG("avg_price") OVER (PARTITION BY "region"
                               ORDER BY "year")                        AS "prev_year_avg"
    FROM region_year_ex_first
)
SELECT
    "year",
    "region",
    ROUND("avg_price",4)                                               AS "avg_purchase_price_usd",
    "rank_within_year",
    ROUND((("avg_price" - "prev_year_avg") * 100.0) / "prev_year_avg",4)
                                                                        AS "pct_change_vs_prev_year"
FROM ranked
ORDER BY "year", "rank_within_year";