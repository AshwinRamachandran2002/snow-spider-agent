WITH sales_2019 AS (
  SELECT
    s."prod_id",
    CAST(strftime('%m', s."time_id") AS INTEGER) AS "month",
    SUM(s."amount_sold") AS "sales_2019"
  FROM "sales" AS s
  JOIN "customers" AS c ON s."cust_id" = c."cust_id"
  JOIN "promotions" AS p ON s."promo_id" = p."promo_id"
  JOIN "channels" AS ch ON s."channel_id" = ch."channel_id"
  WHERE c."country_id" = (
      SELECT "country_id" FROM "countries" WHERE "country_name" = 'France'
  )
  AND p."promo_total_id" = 1
  AND ch."channel_total_id" = 1
  AND strftime('%Y', s."time_id") = '2019'
  GROUP BY s."prod_id", "month"
),
sales_2020 AS (
  SELECT
    s."prod_id",
    CAST(strftime('%m', s."time_id") AS INTEGER) AS "month",
    SUM(s."amount_sold") AS "sales_2020"
  FROM "sales" AS s
  JOIN "customers" AS c ON s."cust_id" = c."cust_id"
  JOIN "promotions" AS p ON s."promo_id" = p."promo_id"
  JOIN "channels" AS ch ON s."channel_id" = ch."channel_id"
  WHERE c."country_id" = (
      SELECT "country_id" FROM "countries" WHERE "country_name" = 'France'
  )
  AND p."promo_total_id" = 1
  AND ch."channel_total_id" = 1
  AND strftime('%Y', s."time_id") = '2020'
  GROUP BY s."prod_id", "month"
),
sales_growth AS (
  SELECT
    s19."prod_id",
    s19."month",
    s19."sales_2019",
    s20."sales_2020",
    (s20."sales_2020" - s19."sales_2019") / s19."sales_2019" AS "growth_rate"
  FROM sales_2019 s19
  JOIN sales_2020 s20 ON s19."prod_id" = s20."prod_id" AND s19."month" = s20."month"
  WHERE s19."sales_2019" > 0  -- Avoid division by zero
),
projected_sales AS (
  SELECT
    s."prod_id",
    s."month",
    s."sales_2020",
    s."growth_rate",
    s."sales_2020" * (1 + s."growth_rate") AS "projected_sales_2021"
  FROM sales_growth s
),
sales_in_usd AS (
  SELECT
    ps."prod_id",
    ps."month",
    ps."projected_sales_2021" * c."to_us" AS "projected_sales_usd"
  FROM projected_sales ps
  JOIN "currency" c ON c."country" = 'France'
    AND c."year" = 2021
    AND c."month" = ps."month"
)
SELECT
  siu."month" AS "Month_num",
  CASE siu."month"
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
  END AS "Month",
  ROUND(AVG(siu."projected_sales_usd"), 4) AS "Average_Projected_Sales_USD"
FROM sales_in_usd siu
GROUP BY siu."month"
ORDER BY "Month_num";