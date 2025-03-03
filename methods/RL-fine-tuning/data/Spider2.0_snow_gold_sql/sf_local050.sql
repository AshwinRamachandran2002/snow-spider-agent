WITH monthly_sales AS (
  SELECT t."calendar_year" AS year,
         t."calendar_month_number" AS month,
         SUM(s."amount_sold" * curr."to_us") AS total_sales_usd
  FROM   "COMPLEX_ORACLE"."COMPLEX_ORACLE"."SALES" s
  JOIN   "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CUSTOMERS" c ON s."cust_id" = c."cust_id"
  JOIN   "COMPLEX_ORACLE"."COMPLEX_ORACLE"."COUNTRIES" co ON c."country_id" = co."country_id"
  JOIN   "COMPLEX_ORACLE"."COMPLEX_ORACLE"."PROMOTIONS" p ON s."promo_id" = p."promo_id"
  JOIN   "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CHANNELS" ch ON s."channel_id" = ch."channel_id"
  JOIN   "COMPLEX_ORACLE"."COMPLEX_ORACLE"."TIMES" t ON s."time_id" = t."time_id"
  JOIN   "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CURRENCY" curr ON t."calendar_year" = curr."year" AND t."calendar_month_number" = curr."month" AND curr."country" = 'France'
  WHERE  co."country_name" = 'France' AND
         p."promo_total_id" = 1 AND
         ch."channel_total_id" = 1 AND
         t."calendar_year" IN (2019, 2020)
  GROUP BY t."calendar_year", t."calendar_month_number"
),
monthly_sales_2019 AS (
  SELECT month, total_sales_usd
  FROM monthly_sales
  WHERE year = 2019
),
monthly_sales_2020 AS (
  SELECT month, total_sales_usd
  FROM monthly_sales
  WHERE year = 2020
),
months AS (
  SELECT DISTINCT month FROM monthly_sales
),
projected_sales AS (
  SELECT m.month,
         COALESCE(ms2019.total_sales_usd, 0) AS sales_2019,
         COALESCE(ms2020.total_sales_usd, 0) AS sales_2020,
         CASE
           WHEN ms2019.total_sales_usd IS NOT NULL AND ms2019.total_sales_usd > 0 THEN
             (COALESCE(ms2020.total_sales_usd, 0) - ms2019.total_sales_usd) / ms2019.total_sales_usd
           ELSE 0
         END AS growth_rate,
         COALESCE(ms2020.total_sales_usd, 0) * (
           1 + CASE
                 WHEN ms2019.total_sales_usd IS NOT NULL AND ms2019.total_sales_usd > 0 THEN
                   (COALESCE(ms2020.total_sales_usd, 0) - ms2019.total_sales_usd) / ms2019.total_sales_usd
                 ELSE 0
               END
         ) AS projected_sales_2021
  FROM months m
  LEFT JOIN monthly_sales_2019 ms2019 ON m.month = ms2019.month
  LEFT JOIN monthly_sales_2020 ms2020 ON m.month = ms2020.month
)
SELECT
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ps.projected_sales_2021) AS "Median_Average_Monthly_Sales_USD"
FROM projected_sales ps;