WITH city_tot AS (        -- total sales per U-S city & quarter
  SELECT c.cust_city,
         t.calendar_quarter_id AS qid,
         SUM(s.amount_sold)    AS amt
  FROM   sales      s
  JOIN   customers  c  ON s.cust_id = c.cust_id
  JOIN   countries  co ON c.country_id = co.country_id
  JOIN   times      t  ON s.time_id   = t.time_id
  WHERE  co.country_iso_code = 'US'
    AND  s.promo_id = 999
    AND  t.calendar_quarter_id IN (1772,1776)        -- Q4-2019 & Q4-2020
  GROUP  BY c.cust_city, t.calendar_quarter_id
),
growth_cities AS (        -- cities whose 2020-Q4 ≥ 120 % of 2019-Q4
  SELECT a.cust_city
  FROM   city_tot a
  JOIN   city_tot b
         ON a.cust_city = b.cust_city
        AND a.qid = 1772
        AND b.qid = 1776
  WHERE  b.amt >= 1.2 * a.amt
),
prod_qtr_sales AS (       -- product sales in those growth-cities
  SELECT s.prod_id,
         t.calendar_quarter_id AS qid,
         SUM(s.amount_sold)    AS amt
  FROM   sales      s
  JOIN   customers  c  ON s.cust_id = c.cust_id
  JOIN   growth_cities gc ON gc.cust_city = c.cust_city
  JOIN   times      t  ON s.time_id = t.time_id
  WHERE  s.promo_id = 999
    AND  t.calendar_quarter_id IN (1772,1776)
  GROUP  BY s.prod_id, t.calendar_quarter_id
),
qtr_tot AS (              -- quarter totals (all products)
  SELECT qid, SUM(amt) AS q_amt
  FROM   prod_qtr_sales
  GROUP  BY qid
),
shares AS (               -- each product’s share of its quarter
  SELECT p.prod_id,
         p.qid,
         1.0 * p.amt / q.q_amt AS share
  FROM   prod_qtr_sales p
  JOIN   qtr_tot        q ON q.qid = p.qid
),
pivot AS (                -- put the two quarter-shares side-by-side
  SELECT s19.prod_id,
         s19.share AS share_2019,
         s20.share AS share_2020,
         ABS(s20.share - s19.share) AS delta
  FROM   shares s19
  JOIN   shares s20
         ON s19.prod_id = s20.prod_id
        AND s19.qid = 1772
        AND s20.qid = 1776
),
prod_tot AS (             -- grand totals across both quarters
  SELECT prod_id, SUM(amt) AS grand_total
  FROM   prod_qtr_sales
  GROUP  BY prod_id
),
ranked AS (               -- rank products by grand total
  SELECT prod_id,
         grand_total,
         ROW_NUMBER() OVER (ORDER BY grand_total DESC) AS rn,
         COUNT(*)  OVER ()                             AS cnt
  FROM   prod_tot
),
top20 AS (                -- keep top 20 % of products
  SELECT prod_id
  FROM   ranked
  WHERE  rn <= CAST(cnt * 0.20 + 0.9999 AS INTEGER)
)
-- ==== final answer ====
SELECT pv.prod_id,
       ROUND(pv.share_2019 * 100, 2) AS share_2019_pct,
       ROUND(pv.share_2020 * 100, 2) AS share_2020_pct,
       ROUND(pv.delta * 100, 4)      AS pct_point_change
FROM   pivot pv
JOIN   top20 t ON t.prod_id = pv.prod_id
ORDER  BY pv.delta ASC
LIMIT 1;