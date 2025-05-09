SELECT
    ROUND(AVG(
        CASE
            WHEN t.lifetime_sales > 0 THEN (t.sales_first_7_days / t.lifetime_sales) * 100
            ELSE NULL
        END
    ), 4) AS "Average_7_Day_LTV_Percentage",
    ROUND(AVG(
        CASE
            WHEN t.lifetime_sales > 0 THEN (t.sales_first_30_days / t.lifetime_sales) * 100
            ELSE NULL
        END
    ), 4) AS "Average_30_Day_LTV_Percentage",
    ROUND(AVG(t.lifetime_sales), 4) AS "Average_Total_Lifetime_Sales"
FROM (
    SELECT
        p."customer_id",
        SUM(p."amount") AS lifetime_sales,
        SUM(
            CASE
                WHEN p."payment_date" >= fp."first_purchase_date"
                 AND p."payment_date" < DATEADD('second', 7 * 86400, fp."first_purchase_date")
                THEN p."amount"
                ELSE 0
            END
        ) AS sales_first_7_days,
        SUM(
            CASE
                WHEN p."payment_date" >= fp."first_purchase_date"
                 AND p."payment_date" < DATEADD('second', 30 * 86400, fp."first_purchase_date")
                THEN p."amount"
                ELSE 0
            END
        ) AS sales_first_30_days
    FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."PAYMENT" p
    JOIN (
        SELECT
            "customer_id",
            MIN("payment_date") AS "first_purchase_date"
        FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."PAYMENT"
        GROUP BY "customer_id"
    ) fp ON p."customer_id" = fp."customer_id"
    GROUP BY p."customer_id"
    HAVING SUM(p."amount") > 0
) t;