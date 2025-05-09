WITH city_sales_2019 AS (
  SELECT c.cust_city,
         SUM(s.amount_sold) AS total_sales_2019
  FROM sales s
  JOIN customers c ON s.cust_id = c.cust_id
  JOIN times t ON s.time_id = t.time_id
  WHERE c.country_id = 52790
    AND t.calendar_year = 2019
    AND t.calendar_quarter_number = 4
    AND s.promo_id = 999
  GROUP BY c.cust_city
),
city_sales_2020 AS (
  SELECT c.cust_city,
         SUM(s.amount_sold) AS total_sales_2020
  FROM sales s
  JOIN customers c ON s.cust_id = c.cust_id
  JOIN times t ON s.time_id = t.time_id
  WHERE c.country_id = 52790
    AND t.calendar_year = 2020
    AND t.calendar_quarter_number = 4
    AND s.promo_id = 999
  GROUP BY c.cust_city
),
city_sales_growth AS (
  SELECT c19.cust_city,
         c19.total_sales_2019,
         c20.total_sales_2020,
         ((c20.total_sales_2020 - c19.total_sales_2019) / c19.total_sales_2019) * 100 AS percent_increase
  FROM city_sales_2019 c19
  JOIN city_sales_2020 c20 ON c19.cust_city = c20.cust_city
  WHERE c19.total_sales_2019 > 0
),
city_growth_cities AS (
  SELECT cust_city
  FROM city_sales_growth
  WHERE percent_increase >= 20
),
product_sales AS (
  SELECT s.prod_id,
         p.prod_name,
         SUM(s.amount_sold) AS total_sales
  FROM sales s
  JOIN customers c ON s.cust_id = c.cust_id
  JOIN products p ON s.prod_id = p.prod_id
  JOIN times t ON s.time_id = t.time_id
  WHERE c.cust_city IN (SELECT cust_city FROM city_growth_cities)
    AND t.calendar_year IN (2019, 2020)
    AND t.calendar_quarter_number = 4
    AND s.promo_id = 999
  GROUP BY s.prod_id, p.prod_name
),
top_products AS (
  SELECT ps.prod_id, ps.prod_name, ps.total_sales
  FROM product_sales ps
  ORDER BY ps.total_sales DESC
  LIMIT (SELECT ROUND(COUNT(*) * 0.2) FROM product_sales)
),
total_sales AS (
  SELECT
    t.calendar_year,
    SUM(s.amount_sold) AS total_amount_sold
  FROM sales s
  JOIN customers c ON s.cust_id = c.cust_id
  JOIN times t ON s.time_id = t.time_id
  WHERE c.cust_city IN (SELECT cust_city FROM city_growth_cities)
    AND t.calendar_year IN (2019, 2020)
    AND t.calendar_quarter_number = 4
    AND s.promo_id = 999
  GROUP BY t.calendar_year
),
product_sales_yearly AS (
  SELECT
    tp.prod_name,
    t.calendar_year,
    SUM(s.amount_sold) AS product_amount_sold
  FROM sales s
  JOIN customers c ON s.cust_id = c.cust_id
  JOIN times t ON s.time_id = t.time_id
  JOIN products p ON s.prod_id = p.prod_id
  JOIN top_products tp ON p.prod_id = tp.prod_id
  WHERE c.cust_city IN (SELECT cust_city FROM city_growth_cities)
    AND t.calendar_year IN (2019, 2020)
    AND t.calendar_quarter_number = 4
    AND s.promo_id = 999
  GROUP BY tp.prod_name, t.calendar_year
),
product_shares AS (
  SELECT
    psy.prod_name,
    psy.calendar_year,
    psy.product_amount_sold,
    ts.total_amount_sold,
    (psy.product_amount_sold * 1.0) / ts.total_amount_sold AS share
  FROM product_sales_yearly psy
  JOIN total_sales ts ON psy.calendar_year = ts.calendar_year
),
product_share_changes AS (
  SELECT
    ps2019.prod_name,
    ps2019.share AS share_2019,
    ps2020.share AS share_2020,
    (ps2020.share - ps2019.share) AS share_change
  FROM product_shares ps2019
  JOIN product_shares ps2020 ON ps2019.prod_name = ps2020.prod_name
  WHERE ps2019.calendar_year = 2019 AND ps2020.calendar_year = 2020
)
SELECT
  ps.prod_name AS Product_Name,
  ROUND(ps.share_2019 * 100, 4) AS Share_2019,
  ROUND(ps.share_2020 * 100, 4) AS Share_2020,
  ROUND((ps.share_2020 - ps.share_2019) * 100, 4) AS Share_Change
FROM product_share_changes ps
ORDER BY Share_Change DESC
;