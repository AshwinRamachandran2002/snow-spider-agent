WITH us_customers AS (
    SELECT c.cust_id ,
           c.cust_city
    FROM   customers   AS c
    JOIN   countries   AS co
           ON c.country_id = co.country_id
    WHERE  co.country_iso_code = 'US'
       OR  co.country_name LIKE 'United States%'
),
-- Q4‑2019 & Q4‑2020 sales in the U.S. with NO promotions
q_sales AS (
    SELECT s.prod_id,
           uc.cust_city,
           t.calendar_year  AS year,
           s.amount_sold
    FROM   sales  AS s
    JOIN   us_customers AS uc
           ON s.cust_id = uc.cust_id
    JOIN   times AS t
           ON s.time_id = t.time_id
    WHERE  s.promo_id = 999
      AND  t.calendar_quarter_number = 4
      AND  t.calendar_year IN (2019,2020)
),
-- city totals for each quarter
city_quarter_sales AS (
    SELECT cust_city,
           year,
           SUM(amount_sold) AS city_amount
    FROM   q_sales
    GROUP  BY cust_city , year
),
-- cities whose Q4‑2020 sales ≥ 120% of Q4‑2019
city_growth AS (
    SELECT c19.cust_city
    FROM   city_quarter_sales c19
    JOIN   city_quarter_sales c20
           ON c19.cust_city = c20.cust_city
    WHERE  c19.year = 2019
      AND  c20.year = 2020
      AND  c20.city_amount >= 1.2 * c19.city_amount
),
-- keep only the growing‑city sales
selected_sales AS (
    SELECT qs.*
    FROM   q_sales qs
    JOIN   city_growth cg
           ON qs.cust_city = cg.cust_city
),
-- overall sales per product (both quarters, growing cities)
product_totals AS (
    SELECT prod_id,
           SUM(amount_sold) AS prod_total
    FROM   selected_sales
    GROUP  BY prod_id
),
-- rank products & keep the top 20 %
prod_rank AS (
    SELECT prod_id,
           prod_total,
           ROW_NUMBER() OVER (ORDER BY prod_total DESC)               AS rn,
           COUNT(*)     OVER ()                                       AS total_cnt
    FROM   product_totals
),
top_products AS (
    SELECT prod_id
    FROM   prod_rank
    WHERE  rn <= ((total_cnt + 4)/5)          -- ceiling( cnt * 0.20 )
),
-- product sales per quarter
product_quarter_sales AS (
    SELECT s.prod_id,
           s.year,
           SUM(s.amount_sold) AS prod_qtr_sales
    FROM   selected_sales s
    JOIN   top_products tp
           ON s.prod_id = tp.prod_id
    GROUP  BY s.prod_id , s.year
),
-- total sales (all products) per quarter in growing cities
total_quarter_sales AS (
    SELECT year,
           SUM(amount_sold) AS total_sales
    FROM   selected_sales
    GROUP  BY year
),
-- product share per quarter
product_shares AS (
    SELECT pqs.prod_id,
           pqs.year,
           pqs.prod_qtr_sales * 1.0 / tqs.total_sales AS share
    FROM   product_quarter_sales pqs
    JOIN   total_quarter_sales  tqs
           ON pqs.year = tqs.year
),
-- share change from 2019‑Q4 to 2020‑Q4
product_share_change AS (
    SELECT ps19.prod_id,
           ps19.share AS share_2019,
           ps20.share AS share_2020,
           ps20.share - ps19.share AS share_change
    FROM   product_shares ps19
    JOIN   product_shares ps20
           ON ps19.prod_id = ps20.prod_id
          AND ps19.year = 2019
          AND ps20.year = 2020
)
SELECT psc.prod_id,
       pr.prod_name,
       ROUND(psc.share_2019 ,4) AS share_2019,
       ROUND(psc.share_2020 ,4) AS share_2020,
       ROUND(psc.share_change,4) AS share_change
FROM   product_share_change psc
JOIN   products pr
       ON psc.prod_id = pr.prod_id
ORDER BY share_change DESC,
         psc.prod_id;