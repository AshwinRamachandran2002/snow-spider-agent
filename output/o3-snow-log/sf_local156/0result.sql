WITH txn_data AS (
    /* 1.  Join transactions with members (for region)
           and with daily BTC prices (for dollar value).               */
    SELECT
        bm."region"                                                        AS "region",
        YEAR(TO_DATE(bt."txn_date",'DD-MM-YYYY'))                          AS "year",
        bt."quantity",                             /* bought quantity  */
        bp."price"                                   /* USD price / BTC */
    FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."BITCOIN_TRANSACTIONS"  bt
    JOIN "BANK_SALES_TRADING"."BANK_SALES_TRADING"."BITCOIN_MEMBERS"       bm
          ON bt."member_id" = bm."member_id"
    JOIN "BANK_SALES_TRADING"."BANK_SALES_TRADING"."BITCOIN_PRICES"        bp
          ON bp."market_date" = bt."txn_date"
         AND bp."ticker"      = 'BTC'
    WHERE bt."txn_type" = 'BUY'           -- purchase only
      AND bt."ticker"   = 'BTC'           -- limit to Bitcoin
      AND bp."price" IS NOT NULL
),
annual_region_price AS (
    /* 2.  Aggregate to annual level per region.                         */
    SELECT
        "region",
        "year",
        SUM("quantity" * "price")                               AS "total_spent",
        SUM("quantity")                                         AS "total_qty",
        SUM("quantity" * "price") / NULLIF(SUM("quantity"),0)   AS "avg_purchase_price"
    FROM txn_data
    GROUP BY "region", "year"
),
exclude_first_year AS (
    /* 3.  Remove each region’s first-ever purchase year.                */
    SELECT
        arp.*,
        DENSE_RANK() OVER (PARTITION BY "region" ORDER BY "year") AS rn
    FROM annual_region_price  arp
),
valid_stats AS (
    SELECT *
    FROM exclude_first_year
    WHERE rn > 1                                     -- drop first year per region
),
rank_and_change AS (
    /* 4.  Rank regions by cost each year and compute YoY change.        */
    SELECT
        "year",
        "region",
        "avg_purchase_price",
        RANK() OVER (PARTITION BY "year"
                     ORDER BY "avg_purchase_price" DESC)       AS "region_rank",
        LAG("avg_purchase_price") OVER (PARTITION BY "region"
                                        ORDER BY "year")       AS prev_year_price
    FROM valid_stats
)
SELECT
    "year",
    "region",
    ROUND("avg_purchase_price",4)                                   AS "avg_purchase_price",
    "region_rank",
    ROUND( ( "avg_purchase_price" - prev_year_price)
          / prev_year_price * 100 , 4 )                             AS "pct_change_from_prev_year"
FROM rank_and_change
ORDER BY "year", "region_rank" NULLS LAST;