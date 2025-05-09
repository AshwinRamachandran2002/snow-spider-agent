WITH country_us AS (
    SELECT country_id
    FROM   countries
    WHERE  country_name = 'United States of America'
),
city_qtr_sales AS (
    SELECT  cu.cust_city          AS city,
            t.calendar_quarter_id AS qtr,
            SUM(s.amount_sold)    AS amt
    FROM    sales      s
    JOIN    customers  cu ON cu.cust_id  = s.cust_id
    JOIN    country_us u  ON u.country_id = cu.country_id
    JOIN    times      t  ON t.time_id   = s.time_id
    WHERE   s.promo_id = 999
      AND   t.calendar_quarter_id IN (1772,1776)   -- Q4‑2019 & Q4‑2020
    GROUP BY cu.cust_city, t.calendar_quarter_id
),
city_ok AS (   -- cities with ≥20 % growth
    SELECT  c19.city
    FROM    city_qtr_sales c19
    JOIN    city_qtr_sales c20
           ON c20.city = c19.city
          AND c19.qtr  = 1772
          AND c20.qtr  = 1776
    WHERE   (c20.amt - c19.amt) * 1.0 / c19.amt >= 0.20
),
filtered_sales AS (
    SELECT  s.prod_id,
            t.calendar_quarter_id AS qtr,
            s.amount_sold
    FROM    sales      s
    JOIN    customers  cu ON cu.cust_id = s.cust_id
    JOIN    city_ok    ok ON ok.city    = cu.cust_city
    JOIN    times      t  ON t.time_id  = s.time_id
    WHERE   s.promo_id = 999
      AND   t.calendar_quarter_id IN (1772,1776)
),
prod_qtr AS (   -- product totals each quarter
    SELECT prod_id, qtr, SUM(amount_sold) AS amt
    FROM   filtered_sales
    GROUP  BY prod_id, qtr
),
tot_qtr AS (    -- overall totals each quarter
    SELECT qtr, SUM(amt) AS tot_amt
    FROM   prod_qtr
    GROUP  BY qtr
),
shares AS (     -- product share of total each quarter
    SELECT p.prod_id,
           p.qtr,
           p.amt * 1.0 / t.tot_amt AS share
    FROM   prod_qtr p
    JOIN   tot_qtr t ON t.qtr = p.qtr
),
share_change AS (
    SELECT s19.prod_id,
           s20.share - s19.share AS pp_change
    FROM   shares s19
    JOIN   shares s20
           ON s20.prod_id = s19.prod_id
          AND s19.qtr = 1772
          AND s20.qtr = 1776
),
prod_totals AS (   -- total sales (both quarters) per product
    SELECT  prod_id,
            SUM(amt) AS total_amt
    FROM    prod_qtr
    GROUP  BY prod_id
),
ranked AS (       -- top 20 % products
    SELECT  prod_id,
            NTILE(5) OVER (ORDER BY total_amt DESC) AS quintile
    FROM    prod_totals
)
SELECT  sc.prod_id AS product_id,
        ROUND(sc.pp_change,4) AS percentage_point_change_in_share_of_total_sales
FROM    share_change sc
JOIN    ranked r ON r.prod_id = sc.prod_id
WHERE   r.quintile = 1              -- top 20 %
ORDER BY ABS(sc.pp_change), sc.prod_id
LIMIT 1;