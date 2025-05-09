WITH
-- United States identifier
us_country AS (
    SELECT country_id
    FROM   countries
    WHERE  country_name LIKE 'United States%'           -- “United States of America”
    LIMIT 1
),

-- Cities whose NO-PROMOTION sales grew ≥20 % from Q4-2019 to Q4-2020
city_growth AS (
    SELECT c.cust_city,
           SUM(CASE WHEN s.time_id BETWEEN '2019-10-01' AND '2019-12-31'
                    THEN s.amount_sold END) AS sales_2019,
           SUM(CASE WHEN s.time_id BETWEEN '2020-10-01' AND '2020-12-31'
                    THEN s.amount_sold END) AS sales_2020
    FROM   sales      AS s
    JOIN   customers  AS c USING (cust_id)
    WHERE  c.country_id = (SELECT country_id FROM us_country)
      AND  s.promo_id  = 999                          -- NO PROMOTION
      AND  s.time_id  BETWEEN '2019-10-01' AND '2020-12-31'
    GROUP  BY c.cust_city
    HAVING sales_2019 > 0
       AND sales_2020 >= 1.2 * sales_2019
),

-- All Q4-2019 + Q4-2020 sales (no promo) restricted to the growth cities
filtered_sales AS (
    SELECT s.*
    FROM   sales      AS s
    JOIN   customers  AS c USING (cust_id)
    WHERE  c.cust_city IN (SELECT cust_city FROM city_growth)
      AND  s.promo_id  = 999
      AND  s.time_id BETWEEN '2019-10-01' AND '2020-12-31'
),

-- Total sales per product within those cities/quarters
product_totals AS (
    SELECT prod_id,
           SUM(amount_sold) AS total_sales
    FROM   filtered_sales
    GROUP  BY prod_id
),

-- Keep the top 20 % of products by total sales
top_products AS (
    SELECT prod_id
    FROM (
        SELECT prod_id,
               total_sales,
               ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rn,
               COUNT(*)    OVER ()                           AS n_all
        FROM   product_totals
    )
    WHERE rn <= 0.2 * n_all
),

-- Market totals for the two quarters
market_totals AS (
    SELECT
        SUM(CASE WHEN time_id BETWEEN '2019-10-01' AND '2019-12-31'
                 THEN amount_sold END) AS market_2019,
        SUM(CASE WHEN time_id BETWEEN '2020-10-01' AND '2020-12-31'
                 THEN amount_sold END) AS market_2020
    FROM   filtered_sales
),

-- Yearly sales for each top product
product_years AS (
    SELECT tp.prod_id,
           SUM(CASE WHEN fs.time_id BETWEEN '2019-10-01' AND '2019-12-31'
                    THEN fs.amount_sold END) AS prod_2019,
           SUM(CASE WHEN fs.time_id BETWEEN '2020-10-01' AND '2020-12-31'
                    THEN fs.amount_sold END) AS prod_2020
    FROM   top_products   AS tp
    JOIN   filtered_sales AS fs ON fs.prod_id = tp.prod_id
    GROUP  BY tp.prod_id
)

-- Final output: share per product and the change in share
SELECT
    py.prod_id,
    ROUND(py.prod_2019 * 1.0 / mt.market_2019, 4) AS share_q4_2019,
    ROUND(py.prod_2020 * 1.0 / mt.market_2020, 4) AS share_q4_2020,
    ROUND(py.prod_2020 * 1.0 / mt.market_2020 
        - py.prod_2019 * 1.0 / mt.market_2019, 4) AS share_change
FROM   product_years   AS py
CROSS  JOIN market_totals AS mt
ORDER  BY share_change DESC;