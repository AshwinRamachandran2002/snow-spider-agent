WITH
first_purchase AS (
    SELECT
        "customer_id",
        MIN("payment_date") AS "first_date"
    FROM "payment"
    GROUP BY "customer_id"
),
ltv AS (
    SELECT
        "customer_id",
        SUM("amount") AS "total_ltv"
    FROM "payment"
    GROUP BY "customer_id"
),
early7 AS (
    SELECT
        p."customer_id",
        SUM(p."amount") AS "early_7_amt"
    FROM "payment" p
    JOIN first_purchase f
      ON p."customer_id" = f."customer_id"
    WHERE (JULIANDAY(p."payment_date") - JULIANDAY(f."first_date")) <= 7
    GROUP BY p."customer_id"
),
early30 AS (
    SELECT
        p."customer_id",
        SUM(p."amount") AS "early_30_amt"
    FROM "payment" p
    JOIN first_purchase f
      ON p."customer_id" = f."customer_id"
    WHERE (JULIANDAY(p."payment_date") - JULIANDAY(f."first_date")) <= 30
    GROUP BY p."customer_id"
),
per_customer AS (
    SELECT
        l."customer_id",
        l."total_ltv",
        COALESCE(e7."early_7_amt", 0)  * 100.0 / l."total_ltv" AS "pct_7d",
        COALESCE(e30."early_30_amt", 0) * 100.0 / l."total_ltv" AS "pct_30d"
    FROM ltv l
    LEFT JOIN early7  e7  ON l."customer_id" = e7."customer_id"
    LEFT JOIN early30 e30 ON l."customer_id" = e30."customer_id"
    WHERE l."total_ltv" > 0
)
SELECT
    ROUND(AVG("pct_7d"), 4)   AS "avg_pct_7d",
    ROUND(AVG("pct_30d"), 4)  AS "avg_pct_30d",
    ROUND(AVG("total_ltv"),4) AS "avg_total_ltv"
FROM per_customer;