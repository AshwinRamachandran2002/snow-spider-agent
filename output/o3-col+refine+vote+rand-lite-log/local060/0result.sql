WITH us_customers AS (          -- U.S. customers
    SELECT cu.cust_id,
           cu.cust_city
    FROM   customers  cu
    JOIN   countries  co ON cu.country_id = co.country_id
    WHERE  co.country_name LIKE 'United States%'              -- U.S.A.
),
base_sales AS (               -- Q4-2019 & Q4-2020 sales with NO PROMOTION
    SELECT s.prod_id,
           uc.cust_city,
           t.calendar_year  AS yr,
           s.amount_sold
    FROM   sales   s
    JOIN   us_customers uc ON s.cust_id = uc.cust_id
    JOIN   times   t       ON s.time_id = t.time_id
    WHERE  s.promo_id              = 999          -- “no promotion”
      AND  t.calendar_quarter_number = 4
      AND  t.calendar_year IN (2019,2020)
),
city_qtr_sales AS (           -- city totals per year
    SELECT cust_city,
           yr,
           SUM(amount_sold) AS city_sales
    FROM   base_sales
    GROUP  BY cust_city, yr
),
rising_cities AS (            -- cities with ≥20 % Q4 growth
    SELECT c19.cust_city
    FROM   city_qtr_sales c19
    JOIN   city_qtr_sales c20
           ON c19.cust_city = c20.cust_city
    WHERE  c19.yr = 2019
      AND  c20.yr = 2020
      AND  c20.city_sales >= 1.2 * c19.city_sales
),
product_tot AS (              -- product totals in those cities (both years)
    SELECT prod_id,
           SUM(amount_sold) AS tot_sales
    FROM   base_sales
    WHERE  cust_city IN (SELECT cust_city FROM rising_cities)
    GROUP  BY prod_id
),
ranked AS (                   -- rank & keep top-20 % of products
    SELECT prod_id,
           tot_sales,
           ROW_NUMBER()  OVER (ORDER BY tot_sales DESC) AS rn,
           COUNT(*)      OVER ()                        AS cnt
    FROM   product_tot
),
top_products AS (
    SELECT prod_id
    FROM   ranked
    WHERE  rn <= 0.2 * cnt                              -- top 20 %
),
prod_year_sales AS (          -- yearly sales per kept product
    SELECT prod_id,
           yr,
           SUM(amount_sold) AS prod_sales
    FROM   base_sales
    WHERE  cust_city IN (SELECT cust_city FROM rising_cities)
      AND  prod_id   IN (SELECT prod_id FROM top_products)
    GROUP  BY prod_id, yr
),
year_tot AS (                 -- grand totals per year (all products)
    SELECT yr,
           SUM(amount_sold) AS tot_sales
    FROM   base_sales
    WHERE  cust_city IN (SELECT cust_city FROM rising_cities)
    GROUP  BY yr
),
shares AS (                   -- compute shares for each kept product
    SELECT p.prod_id,
           pr.prod_name,
           SUM(CASE WHEN yr = 2019 THEN prod_sales END) /
           (SELECT tot_sales FROM year_tot WHERE yr = 2019)  AS share_2019,
           SUM(CASE WHEN yr = 2020 THEN prod_sales END) /
           (SELECT tot_sales FROM year_tot WHERE yr = 2020)  AS share_2020
    FROM   prod_year_sales p
    JOIN   products pr ON p.prod_id = pr.prod_id
    GROUP  BY p.prod_id, pr.prod_name
)
SELECT prod_id,
       prod_name,
       share_2019,
       share_2020,
       (COALESCE(share_2020,0) - COALESCE(share_2019,0)) AS share_change
FROM   shares
ORDER BY share_change DESC;