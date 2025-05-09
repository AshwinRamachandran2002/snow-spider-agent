WITH payments_ts AS (
    SELECT
        "customer_id",
        "amount",
        TO_TIMESTAMP("payment_date") AS "payment_ts"
    FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."PAYMENT"
),
first_purchase AS (
    SELECT
        "customer_id",
        MIN("payment_ts") AS "first_purchase_ts"
    FROM payments_ts
    GROUP BY "customer_id"
),
ltv AS (
    SELECT
        "customer_id",
        SUM("amount") AS "ltv_total"
    FROM payments_ts
    GROUP BY "customer_id"
    HAVING SUM("amount") > 0            -- exclude zero-LTV customers
),
sales_7d AS (
    SELECT
        p."customer_id",
        SUM(p."amount") AS "sales_7d"
    FROM payments_ts p
    JOIN first_purchase f
      ON p."customer_id" = f."customer_id"
    WHERE p."payment_ts" <= DATEADD(day, 7, f."first_purchase_ts")   -- exact 7×24-hour window
    GROUP BY p."customer_id"
),
sales_30d AS (
    SELECT
        p."customer_id",
        SUM(p."amount") AS "sales_30d"
    FROM payments_ts p
    JOIN first_purchase f
      ON p."customer_id" = f."customer_id"
    WHERE p."payment_ts" <= DATEADD(day, 30, f."first_purchase_ts")  -- exact 30×24-hour window
    GROUP BY p."customer_id"
),
percentages AS (
    SELECT
        l."customer_id",
        l."ltv_total",
        COALESCE(s7."sales_7d",  0) / l."ltv_total" AS "pct_7d",
        COALESCE(s30."sales_30d", 0) / l."ltv_total" AS "pct_30d"
    FROM ltv l
    LEFT JOIN sales_7d  s7  ON l."customer_id" = s7."customer_id"
    LEFT JOIN sales_30d s30 ON l."customer_id" = s30."customer_id"
)
SELECT
    ROUND(AVG("pct_7d"),  4) AS "avg_pct_7d",
    ROUND(AVG("pct_30d"), 4) AS "avg_pct_30d",
    ROUND(AVG("ltv_total"),4) AS "avg_ltv"
FROM percentages;