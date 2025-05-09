WITH monthly_sales AS (
    SELECT T."calendar_month_number" AS "month",
        SUM(CASE WHEN T."calendar_year" = 2019 THEN S."amount_sold" END) AS "sales_2019",
        SUM(CASE WHEN T."calendar_year" = 2020 THEN S."amount_sold" END) AS "sales_2020"
    FROM "COMPLEX_ORACLE"."COMPLEX_ORACLE"."SALES" S
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CUSTOMERS" C ON S."cust_id" = C."cust_id"
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."COUNTRIES" CO ON C."country_id" = CO."country_id"
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."TIMES" T ON S."time_id" = T."time_id"
    WHERE CO."country_name" = 'France'
        AND T."calendar_year" IN (2019, 2020)
    GROUP BY T."calendar_month_number"
),
projected_sales AS (
    SELECT ms."month",
        ms."sales_2019",
        ms."sales_2020",
        COALESCE((ms."sales_2020" - ms."sales_2019") / NULLIF(ms."sales_2019", 0), 0) AS "growth_rate",
        ms."sales_2020" * (1 + COALESCE((ms."sales_2020" - ms."sales_2019") / NULLIF(ms."sales_2019", 0), 0)) AS "projected_sales_2021"
    FROM monthly_sales ms
),
exchange_rates AS (
    SELECT "month", "to_us"
    FROM "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CURRENCY"
    WHERE "country" = 'France' AND "year" = 2021
)
SELECT
    CASE ps."month"
        WHEN 1 THEN 'January'
        WHEN 2 THEN 'February'
        WHEN 3 THEN 'March'
        WHEN 4 THEN 'April'
        WHEN 5 THEN 'May'
        WHEN 6 THEN 'June'
        WHEN 7 THEN 'July'
        WHEN 8 THEN 'August'
        WHEN 9 THEN 'September'
        WHEN 10 THEN 'October'
        WHEN 11 THEN 'November'
        WHEN 12 THEN 'December'
        ELSE 'Unknown'
    END AS "Month",
    ROUND(ps."projected_sales_2021" * COALESCE(er."to_us", 1.0), 4) AS "Projected_Sales_USD"
FROM projected_sales ps
LEFT JOIN exchange_rates er ON ps."month" = er."month"
ORDER BY ps."month";