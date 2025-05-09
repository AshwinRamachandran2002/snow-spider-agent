WITH first_purchase AS (
    SELECT
        "customer_id",
        MIN("payment_date") AS "first_purchase"
    FROM "payment"
    GROUP BY "customer_id"
),
per_customer AS (
    SELECT
        p."customer_id",
        SUM(p."amount") AS "total_ltv",
        SUM(
            CASE
                WHEN p."payment_date" <= DATETIME(fp."first_purchase", '+7 days')
                THEN p."amount" ELSE 0
            END
        ) AS "ltv_7d",
        SUM(
            CASE
                WHEN p."payment_date" <= DATETIME(fp."first_purchase", '+30 days')
                THEN p."amount" ELSE 0
            END
        ) AS "ltv_30d"
    FROM "payment" AS p
    JOIN first_purchase AS fp USING ("customer_id")
    GROUP BY p."customer_id"
    HAVING SUM(p."amount") > 0          -- exclude zero-LTV customers
)
SELECT
    ROUND(AVG(("ltv_7d"  * 100.0) / "total_ltv"), 4) AS "avg_pct_7d",
    ROUND(AVG(("ltv_30d" * 100.0) / "total_ltv"), 4) AS "avg_pct_30d",
    ROUND(AVG("total_ltv"),                          4) AS "avg_total_ltv"
FROM per_customer;