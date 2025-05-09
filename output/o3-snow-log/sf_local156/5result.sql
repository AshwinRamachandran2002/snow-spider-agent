WITH txn_buy AS (   -- 1. keep only purchase transactions and convert the date
    SELECT
        bt."member_id",
        bt."ticker",
        TO_DATE(bt."txn_date",'DD-MM-YYYY')        AS "txn_dt",
        bt."quantity"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."BITCOIN_TRANSACTIONS" bt
    WHERE bt."txn_type" = 'BUY'
),

txn_price AS (      -- 2. attach daily market price and member’s region
    SELECT
        tb."member_id",
        bm."region",
        tb."ticker",
        tb."txn_dt",
        bp."price",
        tb."quantity",
        YEAR(tb."txn_dt")                          AS "year",
        tb."quantity" * bp."price"                 AS "spend"
    FROM txn_buy tb
    JOIN BANK_SALES_TRADING.BANK_SALES_TRADING."BITCOIN_PRICES"  bp
         ON bp."ticker" = tb."ticker"
        AND TO_DATE(bp."market_date",'DD-MM-YYYY') = tb."txn_dt"
    JOIN BANK_SALES_TRADING.BANK_SALES_TRADING."BITCOIN_MEMBERS" bm
         ON bm."member_id" = tb."member_id"
),

agg_region_year AS (    -- 3. yearly totals and average purchase price
    SELECT
        "region",
        "year",
        SUM("spend")                        AS total_spend,
        SUM("quantity")                     AS total_qty,
        SUM("spend") / NULLIF(SUM("quantity"),0)  AS avg_price
    FROM txn_price
    GROUP BY "region","year"
),

exclude_first_year AS ( -- 4. drop the first year observed for each region
    SELECT
        ary.*,
        FIRST_VALUE("year") OVER (PARTITION BY "region" ORDER BY "year") AS first_year_region
    FROM agg_region_year ary
),

final_prep AS (
    SELECT  "region","year",avg_price
    FROM    exclude_first_year
    WHERE   "year" > first_year_region
),

with_change AS (       -- 5. calculate YoY % change per region
    SELECT
        *,
        LAG(avg_price) OVER (PARTITION BY "region" ORDER BY "year")                       AS prev_price,
        CASE 
            WHEN LAG(avg_price) OVER (PARTITION BY "region" ORDER BY "year") IS NULL 
            THEN NULL
            ELSE (avg_price
                  - LAG(avg_price) OVER (PARTITION BY "region" ORDER BY "year"))
                 / LAG(avg_price) OVER (PARTITION BY "region" ORDER BY "year") * 100
        END                                                                                AS pct_change
    FROM final_prep
),

with_rank AS (         -- 6. rank regions by yearly average purchase price
    SELECT
        "year",
        "region",
        avg_price,
        pct_change,
        RANK() OVER (PARTITION BY "year" ORDER BY avg_price DESC)  AS price_rank
    FROM with_change
)

SELECT
    "year",
    "region",
    ROUND(avg_price,4)                   AS avg_purchase_price,
    price_rank,
    ROUND(pct_change,4)                  AS pct_change_vs_prev_year
FROM with_rank
ORDER BY "year", price_rank NULLS LAST;