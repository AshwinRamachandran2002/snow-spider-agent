WITH first_purchase AS (
    SELECT 
        "customer_id",
        MIN("payment_date") AS "start_date"
    FROM "payment"
    GROUP BY "customer_id"
),
ltv AS (
    SELECT
        p."customer_id",
        SUM(p."amount") AS "total_ltv",
        SUM(
            CASE 
                WHEN (strftime('%s', p."payment_date") - strftime('%s', fp."start_date")) 
                        < 7*24*60*60 THEN p."amount"
                ELSE 0 
            END
        ) AS "ltv_7d",
        SUM(
            CASE 
                WHEN (strftime('%s', p."payment_date") - strftime('%s', fp."start_date")) 
                        < 30*24*60*60 THEN p."amount"
                ELSE 0 
            END
        ) AS "ltv_30d"
    FROM "payment" AS p
    JOIN first_purchase AS fp USING ("customer_id")
    GROUP BY p."customer_id"
    HAVING SUM(p."amount") > 0          -- exclude zero-LTV customers
)
SELECT
    ROUND(AVG(100.0 * "ltv_7d"  / "total_ltv"), 4) AS "avg_pct_ltv_7d",
    ROUND(AVG(100.0 * "ltv_30d" / "total_ltv"), 4) AS "avg_pct_ltv_30d",
    ROUND(AVG("total_ltv"), 4)                     AS "avg_total_ltv"
FROM ltv;