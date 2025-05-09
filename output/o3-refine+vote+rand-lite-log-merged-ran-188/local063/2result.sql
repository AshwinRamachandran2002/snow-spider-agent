WITH
us_id AS (                          -- United States id
  SELECT country_id 
  FROM   countries 
  WHERE  country_name LIKE '%United States%' 
  LIMIT  1
),
-- cities whose promo-999 sales grew ≥20 % from Q4-2019 to Q4-2020
growth_cities AS (
  SELECT c.cust_city AS city,
         SUM(CASE WHEN t.calendar_quarter_id = 1772 THEN s.amount_sold END) AS amt19,
         SUM(CASE WHEN t.calendar_quarter_id = 1776 THEN s.amount_sold END) AS amt20
  FROM   sales      s
  JOIN   times      t ON s.time_id = t.time_id
  JOIN   customers  c ON s.cust_id = c.cust_id
  WHERE  t.calendar_quarter_id IN (1772,1776)
    AND  s.promo_id = 999
    AND  c.country_id = (SELECT country_id FROM us_id)
  GROUP  BY c.cust_city
  HAVING amt19 IS NOT NULL
     AND amt20 >= 1.2 * amt19
),
-- sales, restricted to the above cities
sales_filt AS (
  SELECT s.prod_id,
         t.calendar_quarter_id AS quarter,
         s.amount_sold
  FROM   sales      s
  JOIN   times      t ON s.time_id = t.time_id
  JOIN   customers  c ON s.cust_id = c.cust_id
  WHERE  t.calendar_quarter_id IN (1772,1776)
    AND  s.promo_id = 999
    AND  c.country_id = (SELECT country_id FROM us_id)
    AND  c.cust_city IN (SELECT city FROM growth_cities)
),
-- total amount per product
prod_totals AS (
  SELECT prod_id,
         SUM(amount_sold) AS total_amt
  FROM   sales_filt
  GROUP  BY prod_id
),
-- 20 % sales threshold
cutoff AS (
  SELECT MAX(total_amt) * 0.20 AS limit_amt
  FROM   prod_totals
),
-- products in the top 20 % of sales
top_prods AS (
  SELECT pt.prod_id
  FROM   prod_totals pt,
         cutoff     c
  WHERE  pt.total_amt >= c.limit_amt
),
-- quarterly amount for those products
prod_qtr_amt AS (
  SELECT sf.prod_id,
         sf.quarter,
         SUM(sf.amount_sold) AS amt
  FROM   sales_filt sf
  WHERE  sf.prod_id IN (SELECT prod_id FROM top_prods)
  GROUP  BY sf.prod_id, sf.quarter
),
-- total amount per quarter (for share calculation)
tot_qtr AS (
  SELECT quarter,
         SUM(amt) AS tot_amt
  FROM   prod_qtr_amt
  GROUP  BY quarter
),
-- market share of each product per quarter
prod_share AS (
  SELECT pqa.prod_id,
         pqa.quarter,
         1.0 * pqa.amt / tq.tot_amt AS share
  FROM   prod_qtr_amt pqa
  JOIN   tot_qtr      tq ON pqa.quarter = tq.quarter
),
-- pivot to get 2019 vs 2020 shares
pivot AS (
  SELECT prod_id,
         MAX(CASE WHEN quarter = 1772 THEN share END) AS share_2019,
         MAX(CASE WHEN quarter = 1776 THEN share END) AS share_2020
  FROM   prod_share
  GROUP  BY prod_id
)
-- product with the smallest absolute change in share (pct-points)
SELECT prod_id,
       (share_2020 - share_2019) * 100.0 AS share_change_pct_point
FROM   pivot
ORDER  BY ABS(share_change_pct_point)
LIMIT  1;