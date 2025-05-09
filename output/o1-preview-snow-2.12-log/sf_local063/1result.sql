WITH
us_sales AS (
  SELECT s."prod_id", s."cust_id", s."time_id", s."promo_id", s."quantity_sold", s."amount_sold", c."cust_city", t."calendar_quarter_id"
  FROM "COMPLEX_ORACLE"."COMPLEX_ORACLE"."SALES" s
  JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CUSTOMERS" c ON s."cust_id" = c."cust_id"
  JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."COUNTRIES" cn ON c."country_id" = cn."country_id"
  JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."TIMES" t ON s."time_id" = t."time_id"
  WHERE cn."country_name" = 'United States of America' AND s."promo_id" = 999
),
city_sales_q4_2019 AS (
  SELECT "cust_city", SUM("amount_sold") AS total_sales_2019
  FROM us_sales
  WHERE "calendar_quarter_id" = 1772
  GROUP BY "cust_city"
),
city_sales_q4_2020 AS (
  SELECT "cust_city", SUM("amount_sold") AS total_sales_2020
  FROM us_sales
  WHERE "calendar_quarter_id" = 1776
  GROUP BY "cust_city"
),
city_sales_growth AS (
  SELECT q19."cust_city",
    q19.total_sales_2019,
    q20.total_sales_2020,
    ((q20.total_sales_2020 - q19.total_sales_2019) / q19.total_sales_2019) AS growth_rate
  FROM city_sales_q4_2019 q19
  JOIN city_sales_q4_2020 q20 ON q19."cust_city" = q20."cust_city"
  WHERE q19.total_sales_2019 > 0
),
cities_with_growth AS (
  SELECT "cust_city"
  FROM city_sales_growth
  WHERE growth_rate >= 0.20
),
sales_in_growth_cities AS (
  SELECT us_sales.*
  FROM us_sales
  JOIN cities_with_growth ON us_sales."cust_city" = cities_with_growth."cust_city"
  WHERE us_sales."calendar_quarter_id" IN (1772, 1776)
),
product_sales AS (
  SELECT "prod_id", "calendar_quarter_id", SUM("amount_sold") AS total_product_sales
  FROM sales_in_growth_cities
  GROUP BY "prod_id", "calendar_quarter_id"
),
total_sales AS (
  SELECT "calendar_quarter_id", SUM("amount_sold") AS total_sales
  FROM sales_in_growth_cities
  GROUP BY "calendar_quarter_id"
),
product_sales_share AS (
  SELECT ps."prod_id", ps."calendar_quarter_id",
    ps.total_product_sales, ts.total_sales,
    (ps.total_product_sales / ts.total_sales) AS sales_share
  FROM product_sales ps
  JOIN total_sales ts ON ps."calendar_quarter_id" = ts."calendar_quarter_id"
),
product_share_change AS (
  SELECT psc1."prod_id",
    (psc2.sales_share - psc1.sales_share) AS percentage_point_change
  FROM product_sales_share psc1
  JOIN product_sales_share psc2 ON psc1."prod_id" = psc2."prod_id"
  WHERE psc1."calendar_quarter_id" = 1772 AND psc2."calendar_quarter_id" = 1776
),
product_totals AS (
  SELECT "prod_id", SUM("amount_sold") AS total_amount_sold
  FROM "COMPLEX_ORACLE"."COMPLEX_ORACLE"."SALES"
  GROUP BY "prod_id"
),
product_rankings AS (
  SELECT "prod_id", total_amount_sold,
    CUME_DIST() OVER (ORDER BY total_amount_sold DESC NULLS LAST) AS cum_dist
  FROM product_totals
),
top_products AS (
  SELECT "prod_id"
  FROM product_rankings
  WHERE cum_dist <= 0.2
),
product_with_min_change AS (
  SELECT psc."prod_id", psc.percentage_point_change
  FROM product_share_change psc
  JOIN top_products tp ON psc."prod_id" = tp."prod_id"
  ORDER BY ABS(psc.percentage_point_change) ASC NULLS LAST, psc."prod_id"
  LIMIT 1
)
SELECT p."prod_id" AS product_id, p."prod_name" AS product_name, ROUND(psc.percentage_point_change, 4) AS percentage_point_change
FROM product_with_min_change psc
JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."PRODUCTS" p ON psc."prod_id" = p."prod_id";