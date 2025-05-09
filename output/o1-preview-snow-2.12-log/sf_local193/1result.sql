SELECT
    ROUND(AVG("percentage_7_days"), 4) AS "Average_7_Day_LTV_Percentage",
    ROUND(AVG("percentage_30_days"), 4) AS "Average_30_Day_LTV_Percentage",
    ROUND(AVG("total_sales"), 4) AS "Average_Total_Lifetime_Sales"
FROM (
    SELECT
        p."customer_id",
        SUM(p."amount") AS "total_sales",
        (SUM(
            CASE
                WHEN p."payment_date_ts" BETWEEN ct."first_purchase_date"
                     AND DATEADD(day, 7, ct."first_purchase_date")
                THEN p."amount"
                ELSE 0
            END
        ) / SUM(p."amount") * 100) AS "percentage_7_days",
        (SUM(
            CASE
                WHEN p."payment_date_ts" BETWEEN ct."first_purchase_date"
                     AND DATEADD(day, 30, ct."first_purchase_date")
                THEN p."amount"
                ELSE 0
            END
        ) / SUM(p."amount") * 100) AS "percentage_30_days"
    FROM (
        SELECT
            "customer_id",
            TO_TIMESTAMP_NTZ("payment_date", 'YYYY-MM-DD HH24:MI:SS.FF3') AS "payment_date_ts",
            "amount"
        FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."PAYMENT"
    ) p
    JOIN (
        SELECT
            "customer_id",
            MIN(TO_TIMESTAMP_NTZ("payment_date", 'YYYY-MM-DD HH24:MI:SS.FF3')) AS "first_purchase_date"
        FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."PAYMENT"
        GROUP BY "customer_id"
    ) ct ON p."customer_id" = ct."customer_id"
    GROUP BY p."customer_id"
    HAVING SUM(p."amount") > 0
)