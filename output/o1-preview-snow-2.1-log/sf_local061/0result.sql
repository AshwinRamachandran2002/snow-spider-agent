WITH sales_2019 AS (
    SELECT
        t."calendar_month_number",
        SUM(s."amount_sold") AS "total_sales_2019"
    FROM
        "COMPLEX_ORACLE"."COMPLEX_ORACLE"."SALES" s
        JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."TIMES" t ON s."time_id" = t."time_id"
        JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CUSTOMERS" c ON s."cust_id" = c."cust_id"
        JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."COUNTRIES" co ON c."country_id" = co."country_id"
    WHERE
        co."country_name" = 'France' AND
        t."calendar_year" = 2019
    GROUP BY
        t."calendar_month_number"
),
sales_2020 AS (
    SELECT
        t."calendar_month_number",
        SUM(s."amount_sold") AS "total_sales_2020"
    FROM
        "COMPLEX_ORACLE"."COMPLEX_ORACLE"."SALES" s
        JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."TIMES" t ON s."time_id" = t."time_id"
        JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CUSTOMERS" c ON s."cust_id" = c."cust_id"
        JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."COUNTRIES" co ON c."country_id" = co."country_id"
    WHERE
        co."country_name" = 'France' AND
        t."calendar_year" = 2020
    GROUP BY
        t."calendar_month_number"
),
projected_sales AS (
    SELECT
        s19."calendar_month_number",
        s19."total_sales_2019",
        s20."total_sales_2020",
        ((s20."total_sales_2020" - s19."total_sales_2019") / NULLIF(s19."total_sales_2019", 0)) AS "percent_change",
        ((s20."total_sales_2020" * ((s20."total_sales_2020" - s19."total_sales_2019") / NULLIF(s19."total_sales_2019", 0))) + s20."total_sales_2020") AS "projected_sales_2021"
    FROM
        sales_2019 s19
        JOIN sales_2020 s20 ON s19."calendar_month_number" = s20."calendar_month_number"
),
months AS (
    SELECT 1 AS "calendar_month_number", 'January' AS "Month" UNION ALL
    SELECT 2, 'February' UNION ALL
    SELECT 3, 'March' UNION ALL
    SELECT 4, 'April' UNION ALL
    SELECT 5, 'May' UNION ALL
    SELECT 6, 'June' UNION ALL
    SELECT 7, 'July' UNION ALL
    SELECT 8, 'August' UNION ALL
    SELECT 9, 'September' UNION ALL
    SELECT 10, 'October' UNION ALL
    SELECT 11, 'November' UNION ALL
    SELECT 12, 'December'
)
SELECT
    months."Month",
    ROUND(COALESCE(ps."projected_sales_2021" * COALESCE(c."to_us", 1), 0), 4) AS "Projected_Sales_USD"
FROM
    months
    LEFT JOIN projected_sales ps ON months."calendar_month_number" = ps."calendar_month_number"
    LEFT JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CURRENCY" c ON c."country" = 'France' AND c."year" = 2021 AND c."month" = months."calendar_month_number"
ORDER BY
    months."calendar_month_number";