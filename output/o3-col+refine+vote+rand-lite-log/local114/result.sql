/*  Web-sales report:
    – number of orders and total sales per region
    – every representative whose cumulative sales equal the regional maximum */
WITH regional_totals AS (
    SELECT r.name                AS region,
           COUNT(o.id)           AS num_orders,
           SUM(o.total_amt_usd)  AS total_sales
    FROM   web_orders      o
    JOIN   web_accounts    a  ON o.account_id  = a.id
    JOIN   web_sales_reps  s  ON a.sales_rep_id = s.id
    JOIN   web_region      r  ON s.region_id    = r.id
    GROUP  BY r.name
),
rep_sales AS (
    SELECT r.name                AS region,
           s.name                AS sales_rep,
           SUM(o.total_amt_usd)  AS rep_sales
    FROM   web_orders      o
    JOIN   web_accounts    a  ON o.account_id  = a.id
    JOIN   web_sales_reps  s  ON a.sales_rep_id = s.id
    JOIN   web_region      r  ON s.region_id    = r.id
    GROUP  BY r.name, s.name
),
max_rep_sales AS (
    SELECT region,
           MAX(rep_sales) AS max_rep_sales
    FROM   rep_sales
    GROUP  BY region
),
top_reps AS (
    SELECT rs.region,
           rs.sales_rep,
           rs.rep_sales
    FROM   rep_sales      rs
    JOIN   max_rep_sales  m  ON rs.region = m.region
                            AND rs.rep_sales = m.max_rep_sales
)
SELECT rt.region,
       rt.num_orders,
       rt.total_sales,
       tr.sales_rep,
       tr.rep_sales
FROM   regional_totals rt
JOIN   top_reps        tr ON rt.region = tr.region
ORDER  BY rt.region, tr.sales_rep;