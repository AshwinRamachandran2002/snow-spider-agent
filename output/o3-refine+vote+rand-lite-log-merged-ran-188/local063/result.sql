WITH growth_cities AS (                 -- cities whose sales grew ≥20 % YoY
    SELECT c.cust_city
    FROM   sales      AS s
    JOIN   customers  AS c  ON s.cust_id   = c.cust_id
    JOIN   countries  AS co ON c.country_id = co.country_id
    JOIN   times      AS t  ON s.time_id   = t.time_id
    WHERE  co.country_name        = 'United States of America'
      AND  s.promo_id             = 999
      AND  t.calendar_quarter_id IN (1772,1776)           -- 2019-Q4, 2020-Q4
    GROUP BY c.cust_city
    HAVING (SUM(CASE WHEN t.calendar_quarter_id = 1776 THEN s.amount_sold END) * 1.0 /
            NULLIF(SUM(CASE WHEN t.calendar_quarter_id = 1772 THEN s.amount_sold END),0) - 1) >= 0.20
),
sales_scope AS (                        -- promo-999 sales in those cities & quarters
    SELECT s.prod_id,
           t.calendar_quarter_id,
           s.amount_sold
    FROM   sales      AS s
    JOIN   customers  AS c  ON s.cust_id = c.cust_id
    JOIN   countries  AS co ON c.country_id = co.country_id
    JOIN   times      AS t  ON s.time_id  = t.time_id
    WHERE  co.country_name        = 'United States of America'
      AND  s.promo_id             = 999
      AND  t.calendar_quarter_id IN (1772,1776)
      AND  c.cust_city           IN (SELECT cust_city FROM growth_cities)
),
prod_tot AS (                           -- total sales per product (both quarters)
    SELECT prod_id,
           SUM(amount_sold) AS grand_total
    FROM   sales_scope
    GROUP BY prod_id
),
ranked AS (                             -- rank products by total sales
    SELECT prod_id,
           grand_total,
           ROW_NUMBER() OVER (ORDER BY grand_total DESC) AS rn,
           COUNT(*)   OVER ()                            AS cnt
    FROM   prod_tot
),
top20 AS (                              -- keep top 20 % by total sales
    SELECT prod_id
    FROM   ranked
    WHERE  rn <= cnt * 0.20
),
prod_qtr AS (                           -- sales per product & quarter (top 20 %)
    SELECT prod_id,
           calendar_quarter_id,
           SUM(amount_sold) AS qtr_sales
    FROM   sales_scope
    WHERE  prod_id IN (SELECT prod_id FROM top20)
    GROUP BY prod_id, calendar_quarter_id
),
total_qtr AS (                          -- total of all top-20 % products per quarter
    SELECT calendar_quarter_id,
           SUM(qtr_sales) AS total_sales
    FROM   prod_qtr
    GROUP BY calendar_quarter_id
),
share_qtr AS (                          -- each product’s % share within the quarter
    SELECT pq.prod_id,
           pq.calendar_quarter_id,
           pq.qtr_sales * 100.0 / tq.total_sales AS pct_share
    FROM   prod_qtr pq
    JOIN   total_qtr tq USING (calendar_quarter_id)
),
diffs AS (                              -- absolute %-point change between quarters
    SELECT s19.prod_id,
           s19.pct_share AS share_2019Q4,
           s20.pct_share AS share_2020Q4,
           ABS(s20.pct_share - s19.pct_share) AS pct_pt_change
    FROM   share_qtr AS s19
    JOIN   share_qtr AS s20
      ON   s19.prod_id             = s20.prod_id
     AND   s19.calendar_quarter_id = 1772          -- 2019-Q4
     AND   s20.calendar_quarter_id = 1776          -- 2020-Q4
)
SELECT prod_id,
       ROUND(share_2019Q4,2) AS share_2019Q4,
       ROUND(share_2020Q4,2) AS share_2020Q4,
       ROUND(pct_pt_change,2) AS pct_point_change
FROM   diffs
ORDER  BY pct_point_change
LIMIT 1;