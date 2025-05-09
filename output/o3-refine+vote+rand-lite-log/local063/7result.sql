WITH us_customers AS (
    SELECT c.cust_id ,
           c.cust_city
    FROM   customers      c
    JOIN   countries      co ON c.country_id = co.country_id
    WHERE  co.country_iso_code = 'US'            -- United States
),  
sales_filtered AS (                              -- only US, promo_id = 999, Q4‑2019 & Q4‑2020
    SELECT s.prod_id,
           uc.cust_city,
           s.amount_sold,
           t.calendar_quarter_id
    FROM   sales      s
    JOIN   times      t  ON s.time_id = t.time_id
    JOIN   us_customers uc ON s.cust_id = uc.cust_id
    WHERE  s.promo_id = 999
      AND  t.calendar_quarter_id IN (1772,1776)  -- 1772 = Q4‑2019, 1776 = Q4‑2020
),
city_q_sales AS (                                -- total per city & quarter
    SELECT cust_city,
           calendar_quarter_id,
           SUM(amount_sold) AS city_sales
    FROM   sales_filtered
    GROUP  BY cust_city, calendar_quarter_id
),
cities_inc AS (                                  -- cities with ≥20 % growth
    SELECT c19.cust_city
    FROM   city_q_sales c19
    JOIN   city_q_sales c20 
           ON c19.cust_city          = c20.cust_city
          AND c19.calendar_quarter_id = 1772
          AND c20.calendar_quarter_id = 1776
    WHERE  c20.city_sales >= 1.2 * c19.city_sales
),
sales_increase AS (                              -- keep rows from ↑ cities only
    SELECT sf.*
    FROM   sales_filtered sf
    JOIN   cities_inc    ci ON sf.cust_city = ci.cust_city
),
prod_q_sales AS (                                -- product totals per quarter
    SELECT prod_id,
           calendar_quarter_id,
           SUM(amount_sold) AS prod_sales
    FROM   sales_increase
    GROUP  BY prod_id, calendar_quarter_id
),
total_q_sales AS (                               -- overall totals per quarter
    SELECT calendar_quarter_id,
           SUM(prod_sales) AS total_sales
    FROM   prod_q_sales
    GROUP  BY calendar_quarter_id
),
prod_share AS (                                  -- product share in each quarter
    SELECT p.prod_id,
           p.calendar_quarter_id,
           1.0 * p.prod_sales / t.total_sales AS share
    FROM   prod_q_sales  p
    JOIN   total_q_sales t 
           ON p.calendar_quarter_id = t.calendar_quarter_id
),
share_change AS (                                -- absolute change in share
    SELECT s19.prod_id,
           ABS(s20.share - s19.share) AS share_delta
    FROM   prod_share s19
    JOIN   prod_share s20
           ON s19.prod_id            = s20.prod_id
          AND s19.calendar_quarter_id = 1772
          AND s20.calendar_quarter_id = 1776
),
prod_total AS (                                  -- overall sales per product (both Qs)
    SELECT prod_id,
           SUM(prod_sales) AS total_sales
    FROM   prod_q_sales
    GROUP  BY prod_id
),
cnt AS ( SELECT COUNT(*) AS n_prod FROM prod_total ),
ranked AS (                                      -- rank products by total sales
    SELECT pt.*,
           ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rn,
           n_prod
    FROM   prod_total pt
    CROSS  JOIN cnt
),
top20 AS (                                       -- top 20 % by total sales
    SELECT prod_id
    FROM   ranked
    WHERE  rn <= CAST((n_prod * 0.20) + 0.9999 AS INTEGER)  -- ceiling of 20 %
)
SELECT sc.prod_id
FROM   share_change sc
JOIN   top20       t  ON sc.prod_id = t.prod_id
ORDER  BY sc.share_delta ASC, sc.prod_id
LIMIT  1;