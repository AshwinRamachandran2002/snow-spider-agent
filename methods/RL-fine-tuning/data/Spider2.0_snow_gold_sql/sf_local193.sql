WITH
    initial_purchase AS (
        SELECT
            p."customer_id",
            MIN(TO_TIMESTAMP(p."payment_date", 'YYYY-MM-DD HH24:MI:SS.FF')) AS "initial_purchase_date"
        FROM
            "SQLITE_SAKILA"."SQLITE_SAKILA"."PAYMENT" p
        GROUP BY
            p."customer_id"
    ),
    total_sales AS (
        SELECT
            p."customer_id",
            SUM(p."amount") AS "total_lifetime_sales"
        FROM
            "SQLITE_SAKILA"."SQLITE_SAKILA"."PAYMENT" p
        GROUP BY
            p."customer_id"
    ),
    sales_7_days AS (
        SELECT
            p."customer_id",
            SUM(p."amount") AS "sales_first_7_days"
        FROM
            "SQLITE_SAKILA"."SQLITE_SAKILA"."PAYMENT" p
        INNER JOIN
            initial_purchase i ON p."customer_id" = i."customer_id"
        WHERE
            DATEDIFF(
                'second',
                i."initial_purchase_date",
                TO_TIMESTAMP(p."payment_date", 'YYYY-MM-DD HH24:MI:SS.FF')
            ) >= 0
            AND DATEDIFF(
                'second',
                i."initial_purchase_date",
                TO_TIMESTAMP(p."payment_date", 'YYYY-MM-DD HH24:MI:SS.FF')
            ) < 604800  -- 7 days in seconds
        GROUP BY
            p."customer_id"
    ),
    sales_30_days AS (
        SELECT
            p."customer_id",
            SUM(p."amount") AS "sales_first_30_days"
        FROM
            "SQLITE_SAKILA"."SQLITE_SAKILA"."PAYMENT" p
        INNER JOIN
            initial_purchase i ON p."customer_id" = i."customer_id"
        WHERE
            DATEDIFF(
                'second',
                i."initial_purchase_date",
                TO_TIMESTAMP(p."payment_date", 'YYYY-MM-DD HH24:MI:SS.FF')
            ) >= 0
            AND DATEDIFF(
                'second',
                i."initial_purchase_date",
                TO_TIMESTAMP(p."payment_date", 'YYYY-MM-DD HH24:MI:SS.FF')
            ) < 2592000  -- 30 days in seconds
        GROUP BY
            p."customer_id"
    )
SELECT
    ROUND(AVG( (COALESCE(s7."sales_first_7_days", 0) / t."total_lifetime_sales") * 100 ), 4) AS "Average_7_Day_LTV_Percentage",
    ROUND(AVG( (COALESCE(s30."sales_first_30_days", 0) / t."total_lifetime_sales") * 100 ), 4) AS "Average_30_Day_LTV_Percentage",
    ROUND(AVG( t."total_lifetime_sales" ), 4) AS "Average_Total_Lifetime_Sales"
FROM
    total_sales t
LEFT JOIN
    sales_7_days s7 ON t."customer_id" = s7."customer_id"
LEFT JOIN
    sales_30_days s30 ON t."customer_id" = s30."customer_id"
WHERE
    t."total_lifetime_sales" > 0;