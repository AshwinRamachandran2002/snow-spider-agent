WITH french_customers AS (
    SELECT c."cust_id"
    FROM "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CUSTOMERS" AS c
    WHERE c."country_id" = (
        SELECT "country_id"
        FROM "COMPLEX_ORACLE"."COMPLEX_ORACLE"."COUNTRIES"
        WHERE "country_name" = 'France'
    )
),
sales_2019 AS (
    SELECT
        s."prod_id",
        t."calendar_month_number" AS "month",
        SUM(s."amount_sold") AS "total_amount_2019"
    FROM "COMPLEX_ORACLE"."COMPLEX_ORACLE"."SALES" AS s
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CUSTOMERS" AS c ON s."cust_id" = c."cust_id"
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."PROMOTIONS" AS p ON s."promo_id" = p."promo_id"
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CHANNELS" AS ch ON s."channel_id" = ch."channel_id"
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."TIMES" AS t ON s."time_id" = t."time_id"
    WHERE c."cust_id" IN (SELECT "cust_id" FROM french_customers)
      AND p."promo_total_id" = 1
      AND ch."channel_total_id" = 1
      AND t."calendar_year" = 2019
    GROUP BY s."prod_id", t."calendar_month_number"
),
sales_2020 AS (
    SELECT
        s."prod_id",
        t."calendar_month_number" AS "month",
        SUM(s."amount_sold") AS "total_amount_2020"
    FROM "COMPLEX_ORACLE"."COMPLEX_ORACLE"."SALES" AS s
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CUSTOMERS" AS c ON s."cust_id" = c."cust_id"
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."PROMOTIONS" AS p ON s."promo_id" = p."promo_id"
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CHANNELS" AS ch ON s."channel_id" = ch."channel_id"
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."TIMES" AS t ON s."time_id" = t."time_id"
    WHERE c."cust_id" IN (SELECT "cust_id" FROM french_customers)
      AND p."promo_total_id" = 1
      AND ch."channel_total_id" = 1
      AND t."calendar_year" = 2020
    GROUP BY s."prod_id", t."calendar_month_number"
),
projected_sales AS (
    SELECT
        s20."prod_id",
        s20."month",
        s19."total_amount_2019",
        s20."total_amount_2020",
        CASE
            WHEN s19."total_amount_2019" IS NULL OR s19."total_amount_2019" = 0 THEN s20."total_amount_2020"
            ELSE POWER(s20."total_amount_2020", 2) / s19."total_amount_2019"
        END AS "Projected_Sales_2021"
    FROM sales_2020 AS s20
    LEFT JOIN sales_2019 AS s19 ON s20."prod_id" = s19."prod_id" AND s20."month" = s19."month"
),
projected_sales_usd AS (
    SELECT
        ps."prod_id",
        ps."month",
        ps."Projected_Sales_2021",
        c."to_us",
        ps."Projected_Sales_2021" * c."to_us" AS "Projected_Sales_2021_USD"
    FROM projected_sales AS ps
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CURRENCY" AS c
        ON c."year" = 2021 AND c."month" = ps."month" AND c."country" = 'France'
),
average_projected_sales AS (
    SELECT
        psu."month",
        ROUND(AVG(psu."Projected_Sales_2021_USD"), 4) AS "Average_projected_sales_USD"
    FROM projected_sales_usd AS psu
    GROUP BY psu."month"
)
SELECT
    LPAD(TO_VARCHAR(aps."month"), 2, '0') AS "Month_num",
    TO_CHAR(DATE_FROM_PARTS(2021, aps."month", 1), 'Mon') AS "Month_name",
    aps."Average_projected_sales_USD"
FROM average_projected_sales AS aps
ORDER BY aps."month";