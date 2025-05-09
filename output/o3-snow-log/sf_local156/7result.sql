WITH
-- 1.  BUY transactions only
txn AS (
    SELECT
        t."member_id",
        t."ticker",
        TO_DATE(t."txn_date",'DD-MM-YYYY')      AS "txn_dt",
        CAST(t."quantity" AS FLOAT)             AS "quantity"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."BITCOIN_TRANSACTIONS" t
    WHERE t."txn_type" = 'BUY'
),

-- 2.  Daily closing prices
px AS (
    SELECT
        p."ticker",
        TO_DATE(p."market_date",'DD-MM-YYYY')   AS "price_dt",
        CAST(p."price" AS FLOAT)                AS "close_price"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."BITCOIN_PRICES" p
),

-- 3.  Join transactions to price & member-region
txn_prc AS (
    SELECT
        m."region",
        DATE_PART('year', t."txn_dt")           AS "calendar_year",
        t."quantity",
        p."close_price"
    FROM txn t
    JOIN BANK_SALES_TRADING.BANK_SALES_TRADING."BITCOIN_MEMBERS" m
          ON m."member_id" = t."member_id"
    JOIN px p
          ON p."ticker"    = t."ticker"
         AND p."price_dt"  = t."txn_dt"
),

-- 4.  Annual spend & quantity, average purchase price
yr_rg AS (
    SELECT
        "region",
        "calendar_year",
        SUM("close_price" * "quantity")                       AS "total_spent",
        SUM("quantity")                                       AS "total_qty",
        ROUND(SUM("close_price" * "quantity")/NULLIF(SUM("quantity"),0),4)
                                                             AS "avg_purchase_price"
    FROM txn_prc
    GROUP BY "region","calendar_year"
),

-- 5.  Drop the first year observed for every region
yr_rg_filt AS (
    SELECT  y.*
    FROM    yr_rg y
    JOIN   (SELECT "region", MIN("calendar_year") AS "first_year"
            FROM yr_rg
            GROUP BY "region") f
      ON y."region" = f."region"
    WHERE y."calendar_year" > f."first_year"
),

-- 6.  Rank regions by cost per year & compute YoY change
final_calc AS (
    SELECT
        y."calendar_year",
        y."region",
        y."avg_purchase_price",
        RANK() OVER (PARTITION BY y."calendar_year"
                     ORDER BY y."avg_purchase_price" DESC NULLS LAST)  AS "rank_in_year",
        LAG(y."avg_purchase_price") OVER (PARTITION BY y."region"
                                          ORDER BY y."calendar_year")  AS "prev_year_price"
    FROM yr_rg_filt y
)

-- 7.  Output
SELECT
    "calendar_year",
    "region",
    "avg_purchase_price",
    "rank_in_year",
    ROUND( ( "avg_purchase_price" - "prev_year_price")
           / NULLIF("prev_year_price",0) * 100 , 4 )                   AS "pct_change_vs_prev_year"
FROM final_calc
ORDER BY "calendar_year",
         "rank_in_year" NULLS LAST;