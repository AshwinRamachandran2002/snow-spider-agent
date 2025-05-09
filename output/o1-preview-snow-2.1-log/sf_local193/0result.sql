WITH customer_first_purchase AS (
    SELECT 
        "customer_id", 
        MIN(TRY_TO_TIMESTAMP("payment_date", 'YYYY-MM-DD HH24:MI:SS.FF3')) AS initial_purchase_date
    FROM SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT
    GROUP BY "customer_id"
),
customer_payments AS (
    SELECT
        p."customer_id",
        TRY_TO_TIMESTAMP(p."payment_date", 'YYYY-MM-DD HH24:MI:SS.FF3') AS "payment_timestamp",
        p."amount",
        cfp.initial_purchase_date
    FROM SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT p
    INNER JOIN customer_first_purchase cfp ON p."customer_id" = cfp."customer_id"
),
customer_ltv AS (
    SELECT
        "customer_id",
        SUM("amount") AS total_ltv,
        SUM(
            CASE 
                WHEN "payment_timestamp" <= initial_purchase_date + INTERVAL '7 DAY' 
                THEN "amount" 
                ELSE 0 
            END
        ) AS ltv_7_days,
        SUM(
            CASE 
                WHEN "payment_timestamp" <= initial_purchase_date + INTERVAL '30 DAY' 
                THEN "amount" 
                ELSE 0 
            END
        ) AS ltv_30_days
    FROM customer_payments
    GROUP BY "customer_id"
    HAVING SUM("amount") > 0
)
SELECT 
    ROUND(AVG(total_ltv), 4) AS "Average_LTV",
    ROUND(AVG((ltv_7_days / total_ltv) * 100), 4) AS "Percentage_LTV_in_first_7_days",
    ROUND(AVG((ltv_30_days / total_ltv) * 100), 4) AS "Percentage_LTV_in_first_30_days"
FROM customer_ltv;