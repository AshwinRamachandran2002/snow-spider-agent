WITH fr_customers AS (
    SELECT c.cust_id
    FROM customers c
    JOIN countries co ON co.country_id = c.country_id
    WHERE co.country_name = 'France'
), 
sales_2019 AS (
    SELECT CAST(SUBSTR(t.time_id,6,2) AS INTEGER) AS month,
           s.prod_id,
           SUM(s.amount_sold) AS amt_2019
    FROM   sales      s
    JOIN   times      t  ON t.time_id   = s.time_id
    JOIN   fr_customers fc ON fc.cust_id = s.cust_id
    JOIN   promotions p  ON p.promo_id   = s.promo_id   AND p.promo_total_id   = 1
    JOIN   channels   ch ON ch.channel_id = s.channel_id AND ch.channel_total_id = 1
    WHERE  SUBSTR(t.time_id,1,4) = '2019'
    GROUP  BY month, s.prod_id
),
sales_2020 AS (
    SELECT CAST(SUBSTR(t.time_id,6,2) AS INTEGER) AS month,
           s.prod_id,
           SUM(s.amount_sold) AS amt_2020
    FROM   sales      s
    JOIN   times      t  ON t.time_id   = s.time_id
    JOIN   fr_customers fc ON fc.cust_id = s.cust_id
    JOIN   promotions p  ON p.promo_id   = s.promo_id   AND p.promo_total_id   = 1
    JOIN   channels   ch ON ch.channel_id = s.channel_id AND ch.channel_total_id = 1
    WHERE  SUBSTR(t.time_id,1,4) = '2020'
    GROUP  BY month, s.prod_id
),
growth AS (
    SELECT s20.month,
           s20.prod_id,
           s20.amt_2020,
           CASE 
               WHEN s19.amt_2019 > 0 
               THEN s20.amt_2020 * 1.0 / s19.amt_2019
           END AS growth_rate
    FROM sales_2020 s20
    JOIN sales_2019 s19 USING (month, prod_id)
    WHERE s19.amt_2019 > 0
),
proj_local AS (
    SELECT month,
           prod_id,
           amt_2020 * growth_rate AS proj_2021_local
    FROM   growth
),
proj_usd AS (
    SELECT pl.month,
           pl.prod_id,
           pl.proj_2021_local * cu.to_us AS proj_2021_usd
    FROM   proj_local pl
    JOIN   currency  cu
           ON cu.country = 'France'
          AND cu.year    = 2021
          AND cu.month   = pl.month
)
SELECT   month,
         ROUND(AVG(proj_2021_usd),4) AS avg_projected_sales_usd
FROM     proj_usd
GROUP BY month
ORDER BY month;