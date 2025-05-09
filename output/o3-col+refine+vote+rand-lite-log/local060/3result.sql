WITH
-- 1. Q4-2019 city-level sales
city_sales_2019 AS (
    SELECT c."cust_city"                        AS city,
           SUM(s."amount_sold")                 AS tot19
    FROM   "sales"        s
    JOIN   "customers"    c  ON c."cust_id"    = s."cust_id"
    JOIN   "countries"    ct ON ct."country_id"= c."country_id"
    JOIN   "times"        t  ON t."time_id"    = s."time_id"
    WHERE  ct."country_name"  LIKE '%United%States%'
      AND  t."calendar_year"  = 2019
      AND  t."calendar_month_number" IN (10,11,12)            -- Q4
    GROUP BY c."cust_city"
),
-- 2. Q4-2020 city-level sales
city_sales_2020 AS (
    SELECT c."cust_city"                        AS city,
           SUM(s."amount_sold")                 AS tot20
    FROM   "sales"        s
    JOIN   "customers"    c  ON c."cust_id"    = s."cust_id"
    JOIN   "countries"    ct ON ct."country_id"= c."country_id"
    JOIN   "times"        t  ON t."time_id"    = s."time_id"
    WHERE  ct."country_name"  LIKE '%United%States%'
      AND  t."calendar_year"  = 2020
      AND  t."calendar_month_number" IN (10,11,12)            -- Q4
    GROUP BY c."cust_city"
),
-- 3. Cities whose Q4-2020 sales rose ≥20 % versus Q4-2019
rising_cities AS (
    SELECT y20.city
    FROM   city_sales_2019 y19
    JOIN   city_sales_2020 y20 USING (city)
    WHERE  y20.tot20 >= y19.tot19 * 1.20
),
-- 4. Product totals (only in rising cities, Q4-2019 & Q4-2020)
prod_q4 AS (
    SELECT s."prod_id",
           SUM(CASE WHEN t."calendar_year" = 2019 THEN s."amount_sold" END) AS sales19,
           SUM(CASE WHEN t."calendar_year" = 2020 THEN s."amount_sold" END) AS sales20
    FROM   "sales"        s
    JOIN   "customers"    c  ON c."cust_id"    = s."cust_id"
    JOIN   "countries"    ct ON ct."country_id"= c."country_id"
    JOIN   "times"        t  ON t."time_id"    = s."time_id"
    WHERE  ct."country_name"  LIKE '%United%States%'
      AND  t."calendar_year"  IN (2019,2020)
      AND  t."calendar_month_number" IN (10,11,12)            -- Q4
      AND  c."cust_city" IN (SELECT city FROM rising_cities)
    GROUP BY s."prod_id"
),
-- 5. Rank products by combined two-year Q4 sales
ranked AS (
    SELECT *,
           RANK()  OVER (ORDER BY (COALESCE(sales19,0)+COALESCE(sales20,0)) DESC) AS rnk,
           COUNT(*) OVER ()                                                       AS total_cnt
    FROM   prod_q4
),
-- 6. Keep top 20 % of those products
top_products AS (
    SELECT *
    FROM   ranked
    WHERE  rnk <= ROUND(total_cnt * 0.20)
)
-- 7. Compute each top product's market share and change
SELECT tp."prod_id",
       ROUND(100.0 * tp.sales19 / SUM(tp.sales19) OVER (), 4) AS share_2019,
       ROUND(100.0 * tp.sales20 / SUM(tp.sales20) OVER (), 4) AS share_2020,
       ROUND( (100.0 * tp.sales20 / SUM(tp.sales20) OVER ())
            - (100.0 * tp.sales19 / SUM(tp.sales19) OVER ()), 4) AS share_change
FROM   top_products tp
ORDER BY share_change DESC;