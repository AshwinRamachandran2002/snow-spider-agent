WITH growth_cities AS (        /* cities whose Q4-20 sales ≥ 120 % of Q4-19 */
    SELECT c.cust_city AS city,
           SUM(CASE WHEN t.calendar_quarter_id = 1772 THEN s.amount_sold END) AS sales_2019,
           SUM(CASE WHEN t.calendar_quarter_id = 1776 THEN s.amount_sold END) AS sales_2020
    FROM   sales     s
    JOIN   customers c ON c.cust_id = s.cust_id
    JOIN   times     t ON t.time_id = s.time_id
    WHERE  c.country_id IN (SELECT country_id
                             FROM countries
                             WHERE country_name LIKE 'United States%')
      AND  s.promo_id = 999
      AND  t.calendar_quarter_id IN (1772,1776)
    GROUP  BY c.cust_city
    HAVING sales_2020 >= 1.20 * sales_2019
),
prod_quarter AS (               /* product sales in those cities, by quarter */
    SELECT s.prod_id,
           t.calendar_quarter_id AS qtr,
           SUM(s.amount_sold)    AS amt
    FROM   sales     s
    JOIN   customers c ON c.cust_id = s.cust_id
    JOIN   times     t ON t.time_id = s.time_id
    WHERE  s.promo_id = 999
      AND  t.calendar_quarter_id IN (1772,1776)
      AND  c.cust_city IN (SELECT city FROM growth_cities)
    GROUP  BY s.prod_id, t.calendar_quarter_id
),
q_tot AS (                      /* total sales amount per quarter */
    SELECT qtr, SUM(amt) AS tot_amt
    FROM   prod_quarter
    GROUP  BY qtr
),
shares AS (                     /* each product’s share per quarter */
    SELECT p.prod_id,
           SUM(CASE WHEN p.qtr = 1772 THEN 1.0*p.amt/q.tot_amt END) AS share_2019,
           SUM(CASE WHEN p.qtr = 1776 THEN 1.0*p.amt/q.tot_amt END) AS share_2020,
           SUM(p.amt)                                               AS tot_sales
    FROM   prod_quarter p
    JOIN   q_tot       q ON q.qtr = p.qtr
    GROUP  BY p.prod_id
    HAVING share_2019 IS NOT NULL AND share_2020 IS NOT NULL
),
ranked AS (                     /* rank by combined sales */
    SELECT *,
           ROW_NUMBER() OVER (ORDER BY tot_sales DESC) AS rn,
           COUNT(*)  OVER ()                           AS n_prod
    FROM   shares
),
top20 AS (                      /* top 20 % of products by sales */
    SELECT *
    FROM   ranked
    WHERE  1.0*rn / n_prod <= 0.20
)
SELECT  t.prod_id,
        pr.prod_name,
        ROUND(t.share_2019,4)            AS share_q4_2019,
        ROUND(t.share_2020,4)            AS share_q4_2020,
        ROUND(t.share_2020 - t.share_2019,4) AS pct_point_change
FROM    top20   t
JOIN    products pr ON pr.prod_id = t.prod_id
ORDER BY ABS(t.share_2020 - t.share_2019)   /* smallest change */
LIMIT 1;