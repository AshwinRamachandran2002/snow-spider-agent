WITH sales_data AS (
    SELECT
        s."prod_id",
        t."calendar_year",
        t."calendar_month_number" AS "month_num",
        SUM(s."amount_sold") AS "total_sales"
    FROM COMPLEX_ORACLE.COMPLEX_ORACLE."SALES" s
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS" c ON s."cust_id" = c."cust_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."COUNTRIES" co ON c."country_id" = co."country_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."PROMOTIONS" p ON s."promo_id" = p."promo_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CHANNELS" ch ON s."channel_id" = ch."channel_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."TIMES" t ON s."time_id" = t."time_id"
    WHERE
        co."country_name" = 'France'
        AND p."promo_total_id" = 1
        AND ch."channel_total_id" = 1
        AND t."calendar_year" IN (2019, 2020)
    GROUP BY
        s."prod_id",
        t."calendar_year",
        t."calendar_month_number"
),
sales_pivot AS (
    SELECT
        COALESCE(sd2019."prod_id", sd2020."prod_id") AS "prod_id",
        COALESCE(sd2019."month_num", sd2020."month_num") AS "month_num",
        sd2019."total_sales" AS "sales_2019",
        sd2020."total_sales" AS "sales_2020"
    FROM
        (SELECT * FROM sales_data WHERE "calendar_year" = 2019) sd2019
        FULL OUTER JOIN (SELECT * FROM sales_data WHERE "calendar_year" = 2020) sd2020
        ON sd2019."prod_id" = sd2020."prod_id"
        AND sd2019."month_num" = sd2020."month_num"
),
projected_sales AS (
    SELECT
        sp."prod_id",
        sp."month_num",
        COALESCE(sp."sales_2019", 0) AS "sales_2019",
        COALESCE(sp."sales_2020", 0) AS "sales_2020",
        CASE
            WHEN COALESCE(sp."sales_2020", 0) = 0 THEN 0
            WHEN COALESCE(sp."sales_2019", 0) = 0 THEN sp."sales_2020"
            ELSE sp."sales_2020" * (1 + ((sp."sales_2020" - sp."sales_2019") / NULLIF(sp."sales_2019", 0)))
        END AS "projected_sales_2021"
    FROM
        sales_pivot sp
),
exchange_rates AS (
    SELECT
        "month" AS "month_num",
        AVG("to_us") AS "exchange_rate"
    FROM COMPLEX_ORACLE.COMPLEX_ORACLE."CURRENCY"
    WHERE
        "country" = 'France'
        AND "year" = 2021
    GROUP BY
        "month"
),
projected_sales_usd AS (
    SELECT
        ps."prod_id",
        ps."month_num",
        ps."projected_sales_2021",
        COALESCE(er."exchange_rate", 1.0) AS "exchange_rate",
        ps."projected_sales_2021" * COALESCE(er."exchange_rate", 1.0) AS "projected_sales_usd"
    FROM
        projected_sales ps
    LEFT JOIN exchange_rates er ON ps."month_num" = er."month_num"
),
months AS (
    SELECT
        DISTINCT
        "calendar_month_number" AS "month_num",
        "calendar_month_name" AS "month_name"
    FROM COMPLEX_ORACLE.COMPLEX_ORACLE."TIMES"
)
SELECT
    LPAD(m."month_num", 2, '0') AS "Month_num",
    m."month_name" AS "Month_name",
    ROUND(AVG(psu."projected_sales_usd"), 4) AS "Average_projected_sales_USD"
FROM
    projected_sales_usd psu
    JOIN months m ON psu."month_num" = m."month_num"
GROUP BY
    m."month_num",
    m."month_name"
ORDER BY
    m."month_num";