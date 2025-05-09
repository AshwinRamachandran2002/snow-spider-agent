WITH
average_sales_2019 AS (
    SELECT
        t."calendar_month_number" AS "month",
        AVG(s."amount_sold" * cu."to_us") AS "avg_sales_2019"
    FROM
        "COMPLEX_ORACLE"."COMPLEX_ORACLE"."SALES" s
        JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CUSTOMERS" c ON s."cust_id" = c."cust_id"
        JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."COUNTRIES" co ON c."country_id" = co."country_id"
        JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."TIMES" t ON s."time_id" = t."time_id"
        JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CURRENCY" cu ON co."country_name" = cu."country"
            AND t."calendar_year" = cu."year"
            AND t."calendar_month_number" = cu."month"
    WHERE
        co."country_name" = 'France' AND t."calendar_year" = 2019
    GROUP BY
        t."calendar_month_number"
),
average_sales_2020 AS (
    SELECT
        t."calendar_month_number" AS "month",
        AVG(s."amount_sold" * cu."to_us") AS "avg_sales_2020"
    FROM
        "COMPLEX_ORACLE"."COMPLEX_ORACLE"."SALES" s
        JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CUSTOMERS" c ON s."cust_id" = c."cust_id"
        JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."COUNTRIES" co ON c."country_id" = co."country_id"
        JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."TIMES" t ON s."time_id" = t."time_id"
        JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CURRENCY" cu ON co."country_name" = cu."country"
            AND t."calendar_year" = cu."year"
            AND t."calendar_month_number" = cu."month"
    WHERE
        co."country_name" = 'France' AND t."calendar_year" = 2020
    GROUP BY
        t."calendar_month_number"
),
avg_sales_change AS (
    SELECT
        a19."month",
        a19."avg_sales_2019",
        a20."avg_sales_2020",
        CASE WHEN a19."avg_sales_2019" = 0 THEN 0
             ELSE ((a20."avg_sales_2020" - a19."avg_sales_2019") / a19."avg_sales_2019")
        END AS "percentage_change"
    FROM
        average_sales_2019 a19
        JOIN average_sales_2020 a20 ON a19."month" = a20."month"
),
projected_avg_sales_2021 AS (
    SELECT
        asc."month",
        ROUND(a20."avg_sales_2020" * (1 + asc."percentage_change"), 4) AS "avg_projected_sales_2021"
    FROM
        avg_sales_change asc
        JOIN average_sales_2020 a20 ON asc."month" = a20."month"
)
SELECT
    ROUND(MEDIAN("avg_projected_sales_2021"), 4) AS "median_average_monthly_projected_sales_in_USD"
FROM
    projected_avg_sales_2021;