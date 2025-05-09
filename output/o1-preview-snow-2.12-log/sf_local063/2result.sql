WITH increased_cities AS (
  SELECT c."cust_city"
  FROM COMPLEX_ORACLE.COMPLEX_ORACLE."SALES" s
  JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS" c ON s."cust_id" = c."cust_id"
  JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."TIMES" t ON s."time_id" = t."time_id"
  JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."COUNTRIES" co ON c."country_id" = co."country_id"
  WHERE t."calendar_quarter_id" IN (1772, 1776)
    AND co."country_name" = 'United States of America'
    AND s."promo_id" = 999
  GROUP BY c."cust_city"
  HAVING SUM(CASE WHEN t."calendar_quarter_id" = 1772 THEN s."amount_sold" END) > 0
     AND (SUM(CASE WHEN t."calendar_quarter_id" = 1776 THEN s."amount_sold" END) /
         SUM(CASE WHEN t."calendar_quarter_id" = 1772 THEN s."amount_sold" END) - 1) >= 0.2
),
product_sales AS (
  SELECT
    s."prod_id",
    SUM(s."amount_sold") AS "total_amount_sold"
  FROM COMPLEX_ORACLE.COMPLEX_ORACLE."SALES" s
  JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS" c ON s."cust_id" = c."cust_id"
  JOIN increased_cities ic ON c."cust_city" = ic."cust_city"
  JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."TIMES" t ON s."time_id" = t."time_id"
  WHERE s."promo_id" = 999
    AND t."calendar_quarter_id" IN (1772, 1776)
  GROUP BY s."prod_id"
),
ranked_products AS (
  SELECT
    ps."prod_id",
    ps."total_amount_sold",
    RANK() OVER (ORDER BY ps."total_amount_sold" DESC NULLS LAST) AS "sales_rank",
    COUNT(*) OVER () AS "total_products"
  FROM product_sales ps
),
top_products AS (
  SELECT
    "prod_id",
    "total_amount_sold",
    "sales_rank",
    "total_products"
  FROM ranked_products
  WHERE "sales_rank" <= CEIL("total_products" * 0.2)
),
total_sales_per_quarter AS (
  SELECT
    t."calendar_quarter_id",
    SUM(s."amount_sold") AS "total_sales"
  FROM COMPLEX_ORACLE.COMPLEX_ORACLE."SALES" s
  JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS" c ON s."cust_id" = c."cust_id"
  JOIN increased_cities ic ON c."cust_city" = ic."cust_city"
  JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."TIMES" t ON s."time_id" = t."time_id"
  WHERE s."promo_id" = 999
    AND t."calendar_quarter_id" IN (1772, 1776)
  GROUP BY t."calendar_quarter_id"
),
product_sales_per_quarter AS (
  SELECT
    s."prod_id",
    t."calendar_quarter_id",
    SUM(s."amount_sold") AS "product_sales"
  FROM COMPLEX_ORACLE.COMPLEX_ORACLE."SALES" s
  JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS" c ON s."cust_id" = c."cust_id"
  JOIN increased_cities ic ON c."cust_city" = ic."cust_city"
  JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."TIMES" t ON s."time_id" = t."time_id"
  WHERE s."promo_id" = 999
    AND t."calendar_quarter_id" IN (1772, 1776)
  GROUP BY s."prod_id", t."calendar_quarter_id"
),
percentage_share AS (
  SELECT
    psq."prod_id",
    psq."calendar_quarter_id",
    psq."product_sales",
    tsq."total_sales",
    (psq."product_sales" / tsq."total_sales") * 100 AS "percentage_share"
  FROM product_sales_per_quarter psq
  JOIN total_sales_per_quarter tsq ON psq."calendar_quarter_id" = tsq."calendar_quarter_id"
),
percentage_change AS (
  SELECT
    tp."prod_id",
    ps2019."percentage_share" AS "percentage_2019",
    ps2020."percentage_share" AS "percentage_2020",
    ROUND(ps2020."percentage_share" - ps2019."percentage_share", 4) AS "percentage_point_change"
  FROM top_products tp
  LEFT JOIN percentage_share ps2019 ON tp."prod_id" = ps2019."prod_id" AND ps2019."calendar_quarter_id" = 1772
  LEFT JOIN percentage_share ps2020 ON tp."prod_id" = ps2020."prod_id" AND ps2020."calendar_quarter_id" = 1776
)
SELECT p."prod_id"::INT AS "product_id", p."prod_name" AS "product_name", pc."percentage_point_change" AS "percentage_point_change"
FROM percentage_change pc
JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."PRODUCTS" p ON pc."prod_id" = p."prod_id"
ORDER BY ABS(pc."percentage_point_change") ASC NULLS LAST, p."prod_id" ASC
LIMIT 1;