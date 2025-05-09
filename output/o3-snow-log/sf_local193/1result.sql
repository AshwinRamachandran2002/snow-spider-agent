/*  Average share of lifetime sales captured in the first 7- and 30-day windows,
    together with the average lifetime sales (LTV) – Snowflake dialect            */

WITH first_payment AS (          -- first purchase moment for every customer
    SELECT  "customer_id",
            MIN(TO_TIMESTAMP("payment_date")) AS "fp_date"
    FROM    "SQLITE_SAKILA"."SQLITE_SAKILA"."PAYMENT"
    GROUP BY "customer_id"
),
lifetime_sales AS (              -- total lifetime sales (LTV)
    SELECT  "customer_id",
            SUM("amount") AS "ltv"
    FROM    "SQLITE_SAKILA"."SQLITE_SAKILA"."PAYMENT"
    GROUP BY "customer_id"
),
sales_7d AS (                    -- sales within 7 × 24 × 60 × 60 seconds
    SELECT  p."customer_id",
            SUM(p."amount") AS "sales_7d"
    FROM    "SQLITE_SAKILA"."SQLITE_SAKILA"."PAYMENT"  p
    JOIN    first_payment                           fp
           ON p."customer_id" = fp."customer_id"
    WHERE   TO_TIMESTAMP(p."payment_date")
            <= DATEADD('second', 604800, fp."fp_date")
    GROUP BY p."customer_id"
),
sales_30d AS (                   -- sales within 30 × 24 × 60 × 60 seconds
    SELECT  p."customer_id",
            SUM(p."amount") AS "sales_30d"
    FROM    "SQLITE_SAKILA"."SQLITE_SAKILA"."PAYMENT"  p
    JOIN    first_payment                           fp
           ON p."customer_id" = fp."customer_id"
    WHERE   TO_TIMESTAMP(p."payment_date")
            <= DATEADD('second', 2592000, fp."fp_date")
    GROUP BY p."customer_id"
),
cust_sales AS (                  -- consolidate figures, keep only positive-LTV customers
    SELECT  lt."customer_id",
            lt."ltv",
            COALESCE(s7."sales_7d",  0) AS "sales_7d",
            COALESCE(s30."sales_30d",0) AS "sales_30d"
    FROM    lifetime_sales lt
    LEFT JOIN sales_7d  s7  ON lt."customer_id" = s7."customer_id"
    LEFT JOIN sales_30d s30 ON lt."customer_id" = s30."customer_id"
    WHERE   lt."ltv" > 0
)
SELECT  ROUND(AVG("sales_7d"  / "ltv"), 4) AS "avg_pct_first_7d",
        ROUND(AVG("sales_30d" / "ltv"), 4) AS "avg_pct_first_30d",
        ROUND(AVG("ltv"), 2)               AS "avg_lifetime_sales"
FROM    cust_sales;