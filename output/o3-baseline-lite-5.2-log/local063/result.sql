WITH sales_us AS (
    SELECT  s.prod_id,
            s.cust_id,
            s.amount_sold,
            t.calendar_quarter_id,
            cu.cust_city
    FROM   sales      AS s
    JOIN   customers  AS cu  ON s.cust_id   = cu.cust_id
    JOIN   countries  AS co  ON cu.country_id = co.country_id
    JOIN   times      AS t   ON s.time_id   = t.time_id
    WHERE  co.country_name LIKE 'United States%'     -- U.S. only
      AND  s.promo_id = 999                          -- given promo
      AND  t.calendar_quarter_id IN (1772,1776)      -- Q4‑2019 & Q4‑2020
),
city_qtr_sales AS (                               -- sales by city/quarter
    SELECT cust_city              AS city,
           calendar_quarter_id    AS qtr,
           SUM(amount_sold)       AS amt
    FROM   sales_us
    GROUP  BY cust_city, calendar_quarter_id
),
city_growth AS (                                  -- cities with ≥20% growth
    SELECT c19.city
    FROM   city_qtr_sales AS c19
    JOIN   city_qtr_sales AS c20
           ON c19.city = c20.city
    WHERE  c19.qtr = 1772
      AND  c20.qtr = 1776
      AND  c20.amt >= 1.2 * c19.amt
),
filtered_sales AS (                               -- sales only in grown cities
    SELECT *
    FROM   sales_us
    WHERE  cust_city IN (SELECT city FROM city_growth)
),
prod_qtr_sales AS (                               -- product sales per quarter
    SELECT prod_id,
           calendar_quarter_id AS qtr,
           SUM(amount_sold)    AS amt
    FROM   filtered_sales
    GROUP  BY prod_id, calendar_quarter_id
),
overall_qtr AS (                                  -- overall totals per quarter
    SELECT qtr,
           SUM(amt) AS total_amt
    FROM   prod_qtr_sales
    GROUP  BY qtr
),
prod_share AS (                                   -- product share per quarter
    SELECT p.prod_id,
           p.qtr,
           p.amt,
           o.total_amt,
           1.0 * p.amt / o.total_amt AS share
    FROM   prod_qtr_sales AS p
    JOIN   overall_qtr    AS o  ON p.qtr = o.qtr
),
prod_stats AS (                                   -- share change & total sales
    SELECT p19.prod_id,
           ABS(p20.share - p19.share) AS share_change,
           (p19.amt + p20.amt)        AS total_sales
    FROM   prod_share AS p19
    JOIN   prod_share AS p20
           ON p19.prod_id = p20.prod_id
          AND p19.qtr    = 1772
          AND p20.qtr    = 1776
),
ranked AS (                                       -- top‑20 % by total sales
    SELECT prod_id,
           share_change,
           ntile(5) OVER (ORDER BY total_sales DESC) AS quintile
    FROM   prod_stats
)
SELECT pr.prod_id,
       pr.prod_name
FROM   products    AS pr
JOIN   ranked      AS r ON pr.prod_id = r.prod_id
WHERE  r.quintile = 1                               -- top 20 %
ORDER  BY r.share_change ASC, pr.prod_id
LIMIT  1;