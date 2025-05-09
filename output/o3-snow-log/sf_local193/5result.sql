WITH first_ts AS (   -- 1) each customer's initial purchase timestamp
    SELECT
        "customer_id",
        MIN(TO_TIMESTAMP("payment_date")) AS "first_payment_ts"
    FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."PAYMENT"
    GROUP BY "customer_id"
),

sales AS (           -- 2) lifetime sales + sales in the first exact 7-day / 30-day windows
    SELECT
        p."customer_id",
        SUM(p."amount") AS "total_ltv",
        SUM(
            CASE
                WHEN DATEDIFF('second',
                              f."first_payment_ts",
                              TO_TIMESTAMP(p."payment_date")) <= 7*24*60*60
                THEN p."amount" ELSE 0
            END) AS "sales_7d",
        SUM(
            CASE
                WHEN DATEDIFF('second',
                              f."first_payment_ts",
                              TO_TIMESTAMP(p."payment_date")) <= 30*24*60*60
                THEN p."amount" ELSE 0
            END) AS "sales_30d"
    FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."PAYMENT" p
    JOIN first_ts f
      ON p."customer_id" = f."customer_id"
    GROUP BY p."customer_id"
),

pct AS (             -- 3) customer-level percentages, exclude zero-LTV customers
    SELECT
        "customer_id",
        "total_ltv",
        "sales_7d"  / "total_ltv" AS "pct_7d",
        "sales_30d" / "total_ltv" AS "pct_30d"
    FROM sales
    WHERE "total_ltv" > 0
)

-- 4) required averages across all (non-zero) customers
SELECT 
    AVG("total_ltv") AS "avg_total_ltv",
    AVG("pct_7d")    AS "avg_pct_7d",
    AVG("pct_30d")   AS "avg_pct_30d"
FROM pct;