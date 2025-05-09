WITH "first_purchase" AS (          -- 1) first purchase timestamp per customer
    SELECT  "customer_id",
            MIN( TO_TIMESTAMP("payment_date") ) AS "first_ts"
    FROM    SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT
    GROUP BY "customer_id"
), 

"customer_ltv" AS (                 -- 2) total, 7-day, and 30-day LTV per customer
    SELECT  p."customer_id",
            SUM(p."amount")                                                                                   AS "total_ltv",
            SUM( CASE WHEN DATEDIFF('second', fp."first_ts", TO_TIMESTAMP(p."payment_date")) <=  604800 THEN p."amount" END ) AS "ltv_7d",
            SUM( CASE WHEN DATEDIFF('second', fp."first_ts", TO_TIMESTAMP(p."payment_date")) <= 2592000 THEN p."amount" END ) AS "ltv_30d"
    FROM    SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT p
    JOIN    "first_purchase" fp
      ON    fp."customer_id" = p."customer_id"
    GROUP BY p."customer_id"
), 

"metrics" AS (                      -- 3) per-customer percentage metrics (exclude zero-LTV)
    SELECT  "customer_id",
            "total_ltv",
            "ltv_7d"  / NULLIF("total_ltv",0)  AS "pct_7d",
            "ltv_30d" / NULLIF("total_ltv",0)  AS "pct_30d"
    FROM    "customer_ltv"
    WHERE   "total_ltv" > 0
)

-- 4) overall averages requested
SELECT  AVG("pct_7d")   AS "avg_pct_7_days",
        AVG("pct_30d")  AS "avg_pct_30_days",
        AVG("total_ltv") AS "avg_total_ltv"
FROM    "metrics";