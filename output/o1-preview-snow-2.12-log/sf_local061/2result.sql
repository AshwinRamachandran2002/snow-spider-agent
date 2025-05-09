WITH sales_data AS (
    SELECT
        S."prod_id",
        T."calendar_month_number" AS "month",
        T."calendar_year",
        SUM(S."amount_sold") AS total_amount_sold
    FROM
        "COMPLEX_ORACLE"."COMPLEX_ORACLE"."SALES" S
        JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CUSTOMERS" C ON S."cust_id" = C."cust_id"
        JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."COUNTRIES" CO ON C."country_id" = CO."country_id"
        JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."TIMES" T ON S."time_id" = T."time_id"
        JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."PROMOTIONS" P ON S."promo_id" = P."promo_id"
        JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CHANNELS" CH ON S."channel_id" = CH."channel_id"
    WHERE
        CO."country_name" = 'France'
        AND P."promo_total_id" = 1
        AND CH."channel_total_id" = 1
        AND T."calendar_year" IN (2019, 2020)
    GROUP BY
        S."prod_id",
        T."calendar_month_number",
        T."calendar_year"
),
sales_pivot AS (
    SELECT
        "prod_id",
        "month",
        MAX(CASE WHEN "calendar_year" = 2019 THEN total_amount_sold ELSE 0 END) AS total_amount_2019,
        MAX(CASE WHEN "calendar_year" = 2020 THEN total_amount_sold ELSE 0 END) AS total_amount_2020
    FROM sales_data
    GROUP BY
        "prod_id",
        "month"
),
sales_growth AS (
    SELECT
        "prod_id",
        "month",
        total_amount_2019,
        total_amount_2020,
        CASE
            WHEN total_amount_2019 > 0 THEN (total_amount_2020 - total_amount_2019) / total_amount_2019
            ELSE 0
        END AS growth_rate,
        CASE
            WHEN total_amount_2019 > 0 THEN total_amount_2020 * (1 + (total_amount_2020 - total_amount_2019)/total_amount_2019)
            ELSE total_amount_2020
        END AS projected_sales_2021
    FROM sales_pivot
),
currency_rates AS (
    SELECT "month", "to_us"
    FROM "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CURRENCY"
    WHERE "country" = 'France' AND "year" = 2021
),
projected_sales_usd AS (
    SELECT
        sg."month",
        sg."prod_id",
        sg.projected_sales_2021 * cr."to_us" AS projected_sales_usd
    FROM sales_growth sg
    JOIN currency_rates cr ON sg."month" = cr."month"
)
SELECT
    LPAD(CAST(ps."month" AS VARCHAR(2)), 2, '0') AS "Month_num",
    TO_CHAR(DATE_FROM_PARTS(2000, ps."month", 1), 'Mon') AS "Month_name",
    ROUND(AVG(ps.projected_sales_usd), 4) AS "Average_projected_sales_USD"
FROM
    projected_sales_usd ps
GROUP BY
    ps."month"
ORDER BY
    ps."month";