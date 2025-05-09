WITH first_pay AS (
    SELECT
        "payment_id",
        "customer_id",
        "amount",
        "payment_date",
        MIN("payment_date") OVER (PARTITION BY "customer_id") AS "first_payment_date"
    FROM SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT
),
customer_ltv AS (
    SELECT
        "customer_id",
        SUM(
            CASE 
                WHEN DATEDIFF('second', "first_payment_date", "payment_date") <= 7 * 24 * 3600 
                THEN "amount" 
                ELSE 0 
            END
        ) AS "ltv_7d",
        SUM(
            CASE 
                WHEN DATEDIFF('second', "first_payment_date", "payment_date") <= 30 * 24 * 3600 
                THEN "amount" 
                ELSE 0 
            END
        ) AS "ltv_30d",
        SUM("amount") AS "total_ltv"
    FROM first_pay
    GROUP BY "customer_id"
)
SELECT
    ROUND(AVG("ltv_7d"  / "total_ltv"), 4) AS "avg_pct_7d",
    ROUND(AVG("ltv_30d" / "total_ltv"), 4) AS "avg_pct_30d",
    ROUND(AVG("total_ltv"), 4)             AS "avg_total_ltv"
FROM customer_ltv
WHERE "total_ltv" > 0;