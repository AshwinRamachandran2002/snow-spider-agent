WITH
-- United States id
us AS (
  SELECT country_id
  FROM   countries
  WHERE  country_name LIKE '%United States%'
  LIMIT 1
),
-- City totals in Q4-2019
city_2019 AS (
  SELECT c.cust_city              AS city,
         SUM(s.amount_sold)       AS amt_2019
  FROM   sales      s
  JOIN   customers  c ON s.cust_id = c.cust_id
  JOIN   times      t ON s.time_id = t.time_id
  WHERE  c.country_id = (SELECT country_id FROM us)
    AND  s.promo_id   = 999
    AND  t.calendar_quarter_id = 1772          -- Q4-2019
  GROUP  BY c.cust_city
),
-- City totals in Q4-2020
city_2020 AS (
  SELECT c.cust_city              AS city,
         SUM(s.amount_sold)       AS amt_2020
  FROM   sales      s
  JOIN   customers  c ON s.cust_id = c.cust_id
  JOIN   times      t ON s.time_id = t.time_id
  WHERE  c.country_id = (SELECT country_id FROM us)
    AND  s.promo_id   = 999
    AND  t.calendar_quarter_id = 1776          -- Q4-2020
  GROUP  BY c.cust_city
),
-- Cities whose sales rose ≥20 %
growth_cities AS (
  SELECT a.city
  FROM   city_2019 a
  JOIN   city_2020 b USING (city)
  WHERE  b.amt_2020 >= 1.20 * a.amt_2019
),
-- Product totals for both quarters in the growth cities
prod_qtr AS (
  SELECT s.prod_id,
         t.calendar_quarter_id AS qid,
         SUM(s.amount_sold)    AS amt
  FROM   sales      s
  JOIN   customers  c ON s.cust_id = c.cust_id
  JOIN   times      t ON s.time_id = t.time_id
  WHERE  s.promo_id = 999
    AND  t.calendar_quarter_id IN (1772,1776)
    AND  c.cust_city IN (SELECT city FROM growth_cities)
    AND  c.country_id = (SELECT country_id FROM us)
  GROUP  BY s.prod_id, t.calendar_quarter_id
),
-- Quarter grand totals
grand_tot AS (
  SELECT qid, SUM(amt) AS total_amt
  FROM   prod_qtr
  GROUP  BY qid
),
-- Sales shares and change per product
prod_stats AS (
  SELECT pq.prod_id,
         SUM(CASE WHEN qid = 1772 THEN amt END) AS amt_2019,
         SUM(CASE WHEN qid = 1776 THEN amt END) AS amt_2020,
         100.0 * SUM(CASE WHEN qid = 1772 THEN amt END) /
               (SELECT total_amt FROM grand_tot WHERE qid = 1772) AS share_2019,
         100.0 * SUM(CASE WHEN qid = 1776 THEN amt END) /
               (SELECT total_amt FROM grand_tot WHERE qid = 1776) AS share_2020
  FROM   prod_qtr pq
  GROUP  BY pq.prod_id
),
-- Top-20 % products by combined sales & choose the one with the smallest share change
ranked AS (
  SELECT ps.*,
         (IFNULL(amt_2019,0) + IFNULL(amt_2020,0))                              AS total_sales,
         NTILE(5) OVER (ORDER BY (IFNULL(amt_2019,0) + IFNULL(amt_2020,0)) DESC) AS quintile,
         (share_2020 - share_2019)                                              AS pct_point_change
  FROM   prod_stats ps
)
SELECT   r.prod_id,
         p.prod_name,
         ROUND(r.share_2019,4)      AS share_2019_pct,
         ROUND(r.share_2020,4)      AS share_2020_pct,
         ROUND(r.pct_point_change,4) AS pct_point_change
FROM     ranked r
JOIN     products p ON p.prod_id = r.prod_id
WHERE    r.quintile = 1            -- top 20 %
ORDER BY ABS(r.pct_point_change) ASC
LIMIT 1;