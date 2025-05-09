WITH "first_purchase" AS (
    SELECT 
        "customer_id",
        MIN("payment_date") AS "first_dt"
    FROM "payment"
    GROUP BY "customer_id"
),
"customer_sales" AS (
    SELECT
        p."customer_id",
        SUM(p."amount") AS "lifetime_sales",
        SUM(
            CASE 
                WHEN p."payment_date" <= datetime(fp."first_dt", '+7 days') 
                THEN p."amount" 
                ELSE 0 
            END
        ) AS "sales_7d",
        SUM(
            CASE 
                WHEN p."payment_date" <= datetime(fp."first_dt", '+30 days') 
                THEN p."amount" 
                ELSE 0 
            END
        ) AS "sales_30d"
    FROM "payment" AS p
    JOIN "first_purchase" AS fp
      ON p."customer_id" = fp."customer_id"
    GROUP BY p."customer_id"
),
"valid_customers" AS (
    SELECT *
    FROM "customer_sales"
    WHERE "lifetime_sales" > 0
)
SELECT 
    ROUND(AVG("lifetime_sales"), 4)                       AS "average_total_lifetime_sales",
    ROUND(AVG("sales_7d" * 1.0 / "lifetime_sales"), 4)    AS "pct_ltv_first_7_days",
    ROUND(AVG("sales_30d" * 1.0 / "lifetime_sales"), 4)   AS "pct_ltv_first_30_days"
FROM "valid_customers";