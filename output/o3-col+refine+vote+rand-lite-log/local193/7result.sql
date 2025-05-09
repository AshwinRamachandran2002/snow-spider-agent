WITH first_payment AS (
    SELECT 
        "customer_id",
        MIN("payment_date") AS "first_payment_date"
    FROM "payment"
    GROUP BY "customer_id"
),
customer_ltv AS (
    SELECT 
        p."customer_id",
        /* sales captured inside the first 7×24-hour window */
        SUM(
            CASE 
                WHEN p."payment_date" 
                     <= DATETIME(fp."first_payment_date", '+7 days') 
                THEN p."amount" 
                ELSE 0 
            END
        ) AS "ltv_7d",
        /* sales captured inside the first 30×24-hour window */
        SUM(
            CASE 
                WHEN p."payment_date" 
                     <= DATETIME(fp."first_payment_date", '+30 days') 
                THEN p."amount" 
                ELSE 0 
            END
        ) AS "ltv_30d",
        /* total lifetime sales */
        SUM(p."amount") AS "total_ltv"
    FROM "payment" AS p
    JOIN first_payment AS fp
      ON p."customer_id" = fp."customer_id"
    GROUP BY p."customer_id"
    HAVING SUM(p."amount") > 0          -- exclude zero-LTV customers
)
SELECT 
    ROUND(AVG(1.0 * "ltv_7d"  / "total_ltv"), 4) AS "avg_pct_7d",
    ROUND(AVG(1.0 * "ltv_30d" / "total_ltv"), 4) AS "avg_pct_30d",
    ROUND(AVG("total_ltv"), 4)                   AS "avg_total_ltv"
FROM customer_ltv;