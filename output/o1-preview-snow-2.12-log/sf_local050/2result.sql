WITH monthly_sales AS (
  SELECT
    t."calendar_month_number" AS "month",
    t."calendar_year" AS "year",
    SUM(s."amount_sold") AS "total_sales"
  FROM "COMPLEX_ORACLE"."COMPLEX_ORACLE"."SALES" s
  JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CUSTOMERS" c ON s."cust_id" = c."cust_id"
  JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."COUNTRIES" co ON c."country_id" = co."country_id"
  JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."TIMES" t ON s."time_id" = t."time_id"
  JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."PROMOTIONS" p ON s."promo_id" = p."promo_id"
  JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CHANNELS" ch ON s."channel_id" = ch."channel_id"
  WHERE co."country_name" = 'France' 
    AND t."calendar_year" IN (2019, 2020)
    AND p."promo_total_id" = 1 
    AND ch."channel_total_id" = 1
  GROUP BY t."calendar_year", t."calendar_month_number"
),
growth_rates AS (
  SELECT
    s2019."month",
    s2019."total_sales" AS "sales_2019",
    s2020."total_sales" AS "sales_2020",
    (s2020."total_sales" - s2019."total_sales") / NULLIF(s2019."total_sales", 0) AS "growth_rate"
  FROM
    (SELECT * FROM monthly_sales WHERE "year" = 2019) s2019
  JOIN 
    (SELECT * FROM monthly_sales WHERE "year" = 2020) s2020
    ON s2019."month" = s2020."month"
),
projected_sales AS (
  SELECT
    g."month",
    g."sales_2020",
    g."growth_rate",
    g."sales_2020" * (1 + g."growth_rate") AS "projected_sales_2021"
  FROM growth_rates g
),
currency_rates AS (
  SELECT
    cu."month",
    cu."to_us"
  FROM "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CURRENCY" cu
  WHERE cu."country" = 'France' 
    AND cu."year" = 2021
),
projected_sales_usd AS (
  SELECT
    ps."month",
    ps."projected_sales_2021" * COALESCE(cr."to_us", 1) AS "projected_sales_usd"
  FROM projected_sales ps
  LEFT JOIN currency_rates cr
    ON ps."month" = cr."month"
)
SELECT
  MEDIAN(psu."projected_sales_usd") AS "Median_Average_Monthly_Sales_USD"
FROM projected_sales_usd psu;