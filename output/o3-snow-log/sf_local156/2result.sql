WITH btc_purchases AS (      -- 1.  All BTC “BUY” transactions with a matched daily USD price and region
    SELECT
        m."region"                                           AS "region",
        t."member_id",
        TO_DATE(t."txn_date",'DD-MM-YYYY')                   AS "txn_dt",
        YEAR(TO_DATE(t."txn_date",'DD-MM-YYYY'))             AS "calendar_year",
        t."quantity"                                         AS "qty",
        p."price"                                            AS "usd_price",
        (t."quantity" * p."price")                           AS "usd_spent"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.BITCOIN_TRANSACTIONS  t
    JOIN BANK_SALES_TRADING.BANK_SALES_TRADING.BITCOIN_MEMBERS       m
          ON t."member_id" = m."member_id"
    JOIN BANK_SALES_TRADING.BANK_SALES_TRADING.BITCOIN_PRICES        p
          ON     p."ticker" = 'BTC'
             AND t."ticker" = 'BTC'
             AND TO_DATE(p."market_date",'DD-MM-YYYY') = TO_DATE(t."txn_date",'DD-MM-YYYY')
    WHERE t."txn_type" = 'BUY'
),

annual_region_cost AS (      -- 2.  Average purchase cost per BTC each year-by-region
    SELECT
        "region",
        "calendar_year",
        SUM("usd_spent")          AS "total_usd_spent",
        SUM("qty")                AS "total_btc_bought",
        ROUND( SUM("usd_spent") / NULLIF(SUM("qty"),0) , 4)  AS "avg_purchase_price"
    FROM btc_purchases
    GROUP BY
        "region",
        "calendar_year"
),

filtered_cost AS (           -- 3.  Exclude the first year available for every region
    SELECT  a.*
    FROM    annual_region_cost a
    JOIN ( SELECT "region",
                  MIN("calendar_year") AS "first_year"
           FROM   annual_region_cost
           GROUP  BY "region") fy
      ON   a."region" = fy."region"
    WHERE  a."calendar_year" > fy."first_year"
),

ranked_cost AS (             -- 4.  Rank regions by cost within each year and compute YoY %
    SELECT
        "calendar_year",
        "region",
        "avg_purchase_price",
        DENSE_RANK() OVER (PARTITION BY "calendar_year"
                           ORDER BY "avg_purchase_price" DESC)       AS "region_rank",
        ROUND(
            100 * ( "avg_purchase_price"
                    - LAG("avg_purchase_price") OVER (PARTITION BY "region"
                                                        ORDER BY "calendar_year") )
            / NULLIF( LAG("avg_purchase_price") OVER (PARTITION BY "region"
                                                       ORDER BY "calendar_year")
                     ,0)
        ,4)                                                         AS "pct_change_vs_prior_year"
    FROM filtered_cost
)

SELECT
    "calendar_year"          AS "year",
    "region",
    "avg_purchase_price",
    "region_rank",
    "pct_change_vs_prior_year"
FROM ranked_cost
ORDER BY
    "calendar_year",
    "region_rank" NULLS LAST;