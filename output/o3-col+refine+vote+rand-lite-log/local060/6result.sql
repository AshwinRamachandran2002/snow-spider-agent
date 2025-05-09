WITH
/* 1. U S customers (country name starts with ‘United States…’) */
us_customers AS (
    SELECT c.cust_id ,
           c.cust_city
    FROM   customers  AS c
    JOIN   countries  AS co
           ON c.country_id = co.country_id
    WHERE  co.country_name LIKE 'United States%'
),

/* 2.  No–promotion sales made by those customers */
us_sales_np AS (
    SELECT s.*,
           u.cust_city
    FROM   sales AS s
    JOIN   us_customers AS u
           ON s.cust_id = u.cust_id
    WHERE  s.promo_id = 999               -- “NO PROMOTION”
),

/* 3.  Q4-2019 and Q4-2020 totals per city                       */
city19 AS (
    SELECT cust_city,
           SUM(amount_sold) AS amt19
    FROM   us_sales_np  AS s
    JOIN   times        AS t  ON s.time_id = t.time_id
    WHERE  t.calendar_year         = 2019
      AND  t.calendar_quarter_number = 4
    GROUP  BY cust_city
),
city20 AS (
    SELECT cust_city,
           SUM(amount_sold) AS amt20
    FROM   us_sales_np  AS s
    JOIN   times        AS t  ON s.time_id = t.time_id
    WHERE  t.calendar_year         = 2020
      AND  t.calendar_quarter_number = 4
    GROUP  BY cust_city
),

/* 4.  Cities whose sales grew ≥20 % from 2019-Q4 to 2020-Q4      */
good_cities AS (
    SELECT c20.cust_city
    FROM   city19 AS c19
    JOIN   city20 AS c20  USING (cust_city)
    WHERE  c20.amt20 >= 1.20 * c19.amt19
),

/* 5.  Total Q4-2019+2020 sales per product inside good cities   */
prod_tot AS (
    SELECT s.prod_id,
           SUM(s.amount_sold) AS tot_sales
    FROM   us_sales_np AS s
    JOIN   times      AS t  ON s.time_id = t.time_id
    WHERE  t.calendar_year IN (2019,2020)
      AND  t.calendar_quarter_number = 4
      AND  s.cust_city IN (SELECT cust_city FROM good_cities)
    GROUP  BY s.prod_id
),

/* 6.  Keep top-20 % products (quintile 1)                       */
ranked_prod AS (
    SELECT prod_id,
           tot_sales,
           NTILE(5) OVER (ORDER BY tot_sales DESC) AS quint
    FROM   prod_tot
),
top_prod AS (
    SELECT prod_id
    FROM   ranked_prod
    WHERE  quint = 1       -- top 20 %
),

/* 7.  Yearly (Q4) totals across all products in good cities     */
year_tot AS (
    SELECT t.calendar_year AS yr,
           SUM(s.amount_sold) AS tot_amt
    FROM   us_sales_np AS s
    JOIN   times      AS t  ON s.time_id = t.time_id
    WHERE  t.calendar_year IN (2019,2020)
      AND  t.calendar_quarter_number = 4
      AND  s.cust_city IN (SELECT cust_city FROM good_cities)
    GROUP  BY t.calendar_year
),

/* 8.  Yearly (Q4) amounts for each top product                  */
prod_year AS (
    SELECT s.prod_id,
           t.calendar_year AS yr,
           SUM(s.amount_sold) AS prod_amt
    FROM   us_sales_np AS s
    JOIN   times      AS t  ON s.time_id = t.time_id
    WHERE  t.calendar_year IN (2019,2020)
      AND  t.calendar_quarter_number = 4
      AND  s.cust_city IN (SELECT cust_city FROM good_cities)
      AND  s.prod_id IN (SELECT prod_id FROM top_prod)
    GROUP  BY s.prod_id, t.calendar_year
)

/* 9.  Final result: shares and their change                     */
SELECT p.prod_id,
       p.prod_name,
       ROUND(
           100.0 * SUM(CASE WHEN yr = 2019 THEN prod_amt END) /
           (SELECT tot_amt FROM year_tot WHERE yr = 2019), 4
       ) AS share_2019Q4,
       ROUND(
           100.0 * SUM(CASE WHEN yr = 2020 THEN prod_amt END) /
           (SELECT tot_amt FROM year_tot WHERE yr = 2020), 4
       ) AS share_2020Q4,
       ROUND(
             ( SUM(CASE WHEN yr = 2020 THEN prod_amt END) /
               (SELECT tot_amt FROM year_tot WHERE yr = 2020) )
           - ( SUM(CASE WHEN yr = 2019 THEN prod_amt END) /
               (SELECT tot_amt FROM year_tot WHERE yr = 2019) )
       , 4) AS share_change
FROM   prod_year
JOIN   products AS p USING (prod_id)
GROUP  BY p.prod_id, p.prod_name
ORDER  BY share_change DESC;