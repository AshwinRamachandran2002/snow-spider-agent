WITH products_with_promotions AS (
  SELECT DISTINCT s2."prod_id"
  FROM COMPLEX_ORACLE.COMPLEX_ORACLE."SALES" s2
  JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."TIMES" t2 ON s2."time_id" = t2."time_id"
  WHERE ((t2."calendar_year" = 2019 AND t2."calendar_quarter_number" = 4)
         OR (t2."calendar_year" = 2020 AND t2."calendar_quarter_number" = 4))
    AND s2."promo_id" <> 999
),
q4_2019_sales AS (
  SELECT s."prod_id", SUM(s."amount_sold") AS total_sales
  FROM COMPLEX_ORACLE.COMPLEX_ORACLE."SALES" s
  JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."TIMES" t ON s."time_id" = t."time_id"
  JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS" c ON s."cust_id" = c."cust_id"
  JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."COUNTRIES" co ON c."country_id" = co."country_id"
  WHERE t."calendar_year" = 2019
    AND t."calendar_quarter_number" = 4
    AND co."country_name" = 'United States of America'
    AND s."promo_id" = 999
    AND s."prod_id" NOT IN (SELECT "prod_id" FROM products_with_promotions)
  GROUP BY s."prod_id"
),
q4_2020_sales AS (
  SELECT s."prod_id", SUM(s."amount_sold") AS total_sales
  FROM COMPLEX_ORACLE.COMPLEX_ORACLE."SALES" s
  JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."TIMES" t ON s."time_id" = t."time_id"
  JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS" c ON s."cust_id" = c."cust_id"
  JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."COUNTRIES" co ON c."country_id" = co."country_id"
  WHERE t."calendar_year" = 2020
    AND t."calendar_quarter_number" = 4
    AND co."country_name" = 'United States of America'
    AND s."promo_id" = 999
    AND s."prod_id" NOT IN (SELECT "prod_id" FROM products_with_promotions)
  GROUP BY s."prod_id"
),
q4_2019_ranked AS (
  SELECT
    qs.*,
    ROW_NUMBER() OVER (ORDER BY qs.total_sales DESC) AS rn,
    COUNT(*) OVER () AS total_products
  FROM q4_2019_sales qs
),
q4_2019_top_20_percent AS (
  SELECT *
  FROM q4_2019_ranked
  WHERE rn <= CEIL(0.2 * total_products)
),
q4_2020_ranked AS (
  SELECT
    qs.*,
    ROW_NUMBER() OVER (ORDER BY qs.total_sales DESC) AS rn,
    COUNT(*) OVER () AS total_products
  FROM q4_2020_sales qs
),
q4_2020_top_20_percent AS (
  SELECT *
  FROM q4_2020_ranked
  WHERE rn <= CEIL(0.2 * total_products)
),
total_top_20_sales_2019 AS (
  SELECT SUM(total_sales) AS total_sales
  FROM q4_2019_top_20_percent
),
total_top_20_sales_2020 AS (
  SELECT SUM(total_sales) AS total_sales
  FROM q4_2020_top_20_percent
),
q4_2019_shares AS (
  SELECT
    qp."prod_id",
    qp.total_sales,
    (qp.total_sales / NULLIF((SELECT total_sales FROM total_top_20_sales_2019), 0)) AS sales_share
  FROM q4_2019_top_20_percent qp
),
q4_2020_shares AS (
  SELECT
    qp."prod_id",
    qp.total_sales,
    (qp.total_sales / NULLIF((SELECT total_sales FROM total_top_20_sales_2020), 0)) AS sales_share
  FROM q4_2020_top_20_percent qp
),
combined_shares AS (
  SELECT
    COALESCE(q19."prod_id", q20."prod_id") AS "Product_ID",
    COALESCE(q19.sales_share, 0) AS sales_share_2019,
    COALESCE(q20.sales_share, 0) AS sales_share_2020,
    (COALESCE(q20.sales_share, 0) - COALESCE(q19.sales_share, 0)) AS "Change_in_Sales_Share"
  FROM q4_2019_shares q19
  FULL OUTER JOIN q4_2020_shares q20 ON q19."prod_id" = q20."prod_id"
)
SELECT "Product_ID",
       ROUND("Change_in_Sales_Share", 4) AS "Change_in_Sales_Share"
FROM combined_shares
ORDER BY "Change_in_Sales_Share" DESC NULLS LAST;