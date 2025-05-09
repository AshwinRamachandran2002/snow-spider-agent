WITH
q_sales AS (       -- sales per U.S. city in the two quarters
    SELECT
        c.cust_city                         AS city,
        t.calendar_quarter_id               AS q_id,
        SUM(s.amount_sold)                  AS amt
    FROM   sales      s
    JOIN   customers  c   ON s.cust_id   = c.cust_id
    JOIN   countries  cn  ON c.country_id = cn.country_id
    JOIN   times      t   ON s.time_id   = t.time_id
    WHERE  cn.country_name LIKE 'United States%'    -- U.S. only
      AND  s.promo_id = 999                         -- promo 999
      AND  t.calendar_quarter_id IN (1772,1776)     -- Q4‑2019, Q4‑2020
    GROUP  BY c.cust_city, t.calendar_quarter_id
),
city_growth AS (    -- cities whose sales grew ≥20 %
    SELECT
        city,
        SUM(CASE WHEN q_id = 1772 THEN amt END) AS amt_2019,
        SUM(CASE WHEN q_id = 1776 THEN amt END) AS amt_2020
    FROM   q_sales
    GROUP  BY city
    HAVING amt_2019 > 0
       AND amt_2020 >= 1.2 * amt_2019
),
prod_quarter AS (   -- product totals in the qualifying cities
    SELECT
        s.prod_id,
        t.calendar_quarter_id AS q_id,
        SUM(s.amount_sold)    AS amt
    FROM   sales      s
    JOIN   customers  c   ON s.cust_id   = c.cust_id
    JOIN   countries  cn  ON c.country_id = cn.country_id
    JOIN   times      t   ON s.time_id   = t.time_id
    JOIN   city_growth g  ON g.city      = c.cust_city
    WHERE  cn.country_name LIKE 'United States%'
      AND  s.promo_id = 999
      AND  t.calendar_quarter_id IN (1772,1776)
    GROUP  BY s.prod_id, t.calendar_quarter_id
),
tot_quarter AS (    -- grand total per quarter
    SELECT q_id, SUM(amt) AS total_amt
    FROM   prod_quarter
    GROUP  BY q_id
),
prod_share AS (     -- each product’s share of its quarter
    SELECT
        pq.prod_id,
        pq.q_id,
        pq.amt,
        pq.amt * 1.0 / tq.total_amt AS share
    FROM   prod_quarter pq
    JOIN   tot_quarter tq ON tq.q_id = pq.q_id
),
prod_stats AS (     -- pivot to one row per product
    SELECT
        prod_id,
        SUM(CASE WHEN q_id = 1772 THEN amt   END) AS amt_2019,
        SUM(CASE WHEN q_id = 1776 THEN amt   END) AS amt_2020,
        SUM(CASE WHEN q_id = 1772 THEN share END) AS share_2019,
        SUM(CASE WHEN q_id = 1776 THEN share END) AS share_2020
    FROM   prod_share
    GROUP  BY prod_id
),
prod_rank AS (      -- add totals and share‑change
    SELECT
        *,
        COALESCE(amt_2019,0) + COALESCE(amt_2020,0)          AS total_amt,
        ABS(COALESCE(share_2020,0) - COALESCE(share_2019,0)) AS share_change
    FROM   prod_stats
),
ranked AS (         -- rank by total sales
    SELECT
        pr.*,
        ROW_NUMBER() OVER (ORDER BY total_amt DESC) AS rn,
        COUNT(*)  OVER ()                            AS cnt
    FROM   prod_rank pr
),
top20 AS (          -- keep top 20 % (round up)
    SELECT *
    FROM   ranked
    WHERE  rn <= ((cnt + 4) / 5)   -- integer math: (cnt+4)/5 ≈ ceil(cnt*0.20)
)
SELECT
    p.prod_id,
    p.prod_name
FROM   top20 t
JOIN   products p ON p.prod_id = t.prod_id
ORDER  BY t.share_change ASC, p.prod_id
LIMIT  1;