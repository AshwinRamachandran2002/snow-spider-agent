WITH first_purchase AS (
    SELECT
        "customer_id",
        MIN("payment_date") AS "first_purchase_ts"
    FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."PAYMENT"
    GROUP BY "customer_id"
),

customer_totals AS (
    SELECT
        "customer_id",
        SUM("amount") AS "total_ltv"
    FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."PAYMENT"
    GROUP BY "customer_id"
    HAVING SUM("amount") > 0          -- exclude customers with zero LTV
),

sales_7d AS (
    SELECT
        p."customer_id",
        SUM(p."amount") AS "sales_7d"
    FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."PAYMENT" p
    JOIN first_purchase fp
      ON p."customer_id" = fp."customer_id"
    WHERE p."payment_date" BETWEEN fp."first_purchase_ts"
                              AND DATEADD('SECOND', 7*24*60*60, fp."first_purchase_ts")
    GROUP BY p."customer_id"
),

sales_30d AS (
    SELECT
        p."customer_id",
        SUM(p."amount") AS "sales_30d"
    FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."PAYMENT" p
    JOIN first_purchase fp
      ON p."customer_id" = fp."customer_id"
    WHERE p."payment_date" BETWEEN fp."first_purchase_ts"
                              AND DATEADD('SECOND', 30*24*60*60, fp."first_purchase_ts")
    GROUP BY p."customer_id"
),

combined AS (
    SELECT
        ct."customer_id",
        ct."total_ltv",
        COALESCE(s7."sales_7d",  0) AS "sales_7d",
        COALESCE(s30."sales_30d", 0) AS "sales_30d"
    FROM customer_totals ct
    LEFT JOIN sales_7d  s7  ON ct."customer_id" = s7."customer_id"
    LEFT JOIN sales_30d s30 ON ct."customer_id" = s30."customer_id"
)

SELECT
    AVG(("sales_7d"  / "total_ltv") * 100) AS "avg_pct_ltv_7d",
    AVG(("sales_30d" / "total_ltv") * 100) AS "avg_pct_ltv_30d",
    AVG("total_ltv")                       AS "avg_total_ltv"
FROM combined;