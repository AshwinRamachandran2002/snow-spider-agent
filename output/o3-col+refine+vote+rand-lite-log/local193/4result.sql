WITH
-- 1) first purchase timestamp for every customer
"first_payment" AS (
    SELECT
        "customer_id",
        MIN("payment_date") AS "first_payment_date"
    FROM "payment"
    GROUP BY "customer_id"
),

-- 2) lifetime value (total sales); keep only customers whose LTV > 0
"lifetime_sales" AS (
    SELECT
        "customer_id",
        SUM("amount") AS "lifetime_sales"
    FROM "payment"
    GROUP BY "customer_id"
    HAVING SUM("amount") > 0
),

-- 3) sales that occur within EXACTLY 7 × 24 hours of the first payment
"sales_7d" AS (
    SELECT
        p."customer_id",
        SUM(p."amount") AS "sales_7d"
    FROM   "payment" p
    JOIN   "first_payment" f
           ON p."customer_id" = f."customer_id"
          AND p."payment_date" <= DATETIME(f."first_payment_date", '+7 days')
    GROUP BY p."customer_id"
),

-- 4) sales that occur within EXACTLY 30 × 24 hours of the first payment
"sales_30d" AS (
    SELECT
        p."customer_id",
        SUM(p."amount") AS "sales_30d"
    FROM   "payment" p
    JOIN   "first_payment" f
           ON p."customer_id" = f."customer_id"
          AND p."payment_date" <= DATETIME(f."first_payment_date", '+30 days')
    GROUP BY p."customer_id"
),

-- 5) combine the metrics per customer
"customer_metrics" AS (
    SELECT
        ls."customer_id",
        ls."lifetime_sales",
        COALESCE(s7."sales_7d", 0)   AS "sales_7d",
        COALESCE(s30."sales_30d", 0) AS "sales_30d"
    FROM "lifetime_sales" ls
    LEFT JOIN "sales_7d"  s7  ON ls."customer_id" = s7."customer_id"
    LEFT JOIN "sales_30d" s30 ON ls."customer_id" = s30."customer_id"
)

-- 6) final averages (rounded to four decimal places)
SELECT
    ROUND(AVG("sales_7d"  / "lifetime_sales"), 4) AS "avg_pct_7d",
    ROUND(AVG("sales_30d" / "lifetime_sales"), 4) AS "avg_pct_30d",
    ROUND(AVG("lifetime_sales"), 4)               AS "avg_lifetime_sales"
FROM "customer_metrics";