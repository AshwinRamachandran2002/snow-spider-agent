WITH us_sales_city_qtr AS (
    SELECT c.cust_city                       AS city,
           t.calendar_quarter_id             AS qtr,
           SUM(s.amount_sold)                AS city_sales
    FROM   sales       s
    JOIN   customers   c   ON c.cust_id   = s.cust_id
    JOIN   countries   co  ON co.country_id = c.country_id
    JOIN   times       t   ON t.time_id  = s.time_id
    WHERE  s.promo_id            = 999
      AND  co.country_iso_code   = 'US'
      AND  t.calendar_quarter_id IN (1772,1776)
    GROUP  BY c.cust_city, t.calendar_quarter_id
),
growth_cities AS (
    SELECT a.city
    FROM   us_sales_city_qtr a
    JOIN   us_sales_city_qtr b
           ON  b.city = a.city
           AND b.qtr  = 1776
    WHERE  a.qtr = 1772
      AND  (b.city_sales - a.city_sales) * 1.0 / a.city_sales >= 0.20
),
product_qtr AS (
    SELECT s.prod_id,
           t.calendar_quarter_id AS qtr,
           SUM(s.amount_sold)    AS prod_sales
    FROM   sales     s
    JOIN   customers c ON c.cust_id = s.cust_id
    JOIN   times     t ON t.time_id = s.time_id
    WHERE  s.promo_id            = 999
      AND  t.calendar_quarter_id IN (1772,1776)
      AND  c.cust_city IN (SELECT city FROM growth_cities)
    GROUP  BY s.prod_id, t.calendar_quarter_id
),
total_qtr AS (
    SELECT qtr, SUM(prod_sales) AS total_sales
    FROM   product_qtr
    GROUP  BY qtr
),
product_share AS (
    SELECT p.prod_id,
           p.qtr,
           p.prod_sales * 1.0 / t.total_sales AS share
    FROM   product_qtr p
    JOIN   total_qtr  t ON t.qtr = p.qtr
),
share_change AS (
    SELECT a.prod_id,
           a.share                 AS share_2019q4,
           b.share                 AS share_2020q4,
           (b.share - a.share)     AS pp_change
    FROM   product_share a
    JOIN   product_share b
           ON  b.prod_id = a.prod_id
           AND b.qtr     = 1776
    WHERE  a.qtr = 1772
),
sales_rank AS (
    SELECT sc.*,
           (SELECT SUM(prod_sales)
            FROM   product_qtr pq
            WHERE  pq.prod_id = sc.prod_id) AS total_prod_sales
    FROM   share_change sc
),
top_20pct AS (
    SELECT *
    FROM   sales_rank
    ORDER  BY total_prod_sales DESC
    LIMIT  (SELECT CAST(COUNT(*) * 0.20 AS INTEGER) FROM sales_rank)
)
SELECT prod_id  AS product_id,
       ROUND(pp_change,4) AS percentage_point_change_in_share_of_total_sales
FROM   top_20pct
ORDER  BY ABS(pp_change) ASC, prod_id
LIMIT 1;