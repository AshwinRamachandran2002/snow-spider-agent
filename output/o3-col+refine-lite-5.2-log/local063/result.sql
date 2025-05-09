WITH growing_cities AS (
    /* U‑S cities whose Q4‑2020 sales ≥ 120 % of Q4‑2019 */
    SELECT a.cust_city
    FROM (
        SELECT cu.cust_city,
               SUM(s.amount_sold) AS amt_2019
        FROM sales      s
        JOIN customers  cu ON cu.cust_id   = s.cust_id
        JOIN countries  co ON co.country_id = cu.country_id
        JOIN times      t  ON t.time_id    = s.time_id
        WHERE co.country_name = 'United States of America'
          AND s.promo_id           = 999
          AND t.calendar_quarter_id = 1772        -- Q4‑2019
        GROUP BY cu.cust_city
    ) a
    JOIN (
        SELECT cu.cust_city,
               SUM(s.amount_sold) AS amt_2020
        FROM sales      s
        JOIN customers  cu ON cu.cust_id   = s.cust_id
        JOIN countries  co ON co.country_id = cu.country_id
        JOIN times      t  ON t.time_id    = s.time_id
        WHERE co.country_name = 'United States of America'
          AND s.promo_id           = 999
          AND t.calendar_quarter_id = 1776        -- Q4‑2020
        GROUP BY cu.cust_city
    ) b  ON a.cust_city = b.cust_city
    WHERE b.amt_2020 >= 1.20 * a.amt_2019
),
prod_tot AS (
    /* total sales (both quarters) per product inside the growing cities */
    SELECT s.prod_id,
           SUM(s.amount_sold) AS total_sales
    FROM sales      s
    JOIN customers  cu ON cu.cust_id = s.cust_id
    JOIN times      t  ON t.time_id  = s.time_id
    WHERE cu.cust_city IN (SELECT cust_city FROM growing_cities)
      AND s.promo_id           = 999
      AND t.calendar_quarter_id IN (1772,1776)
    GROUP BY s.prod_id
),
ranked AS (
    /* rank products by total sales & keep the top 20 % */
    SELECT prod_id,
           total_sales,
           ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rn,
           COUNT(*)  OVER ()                             AS cnt
    FROM prod_tot
),
top20 AS (
    SELECT prod_id
    FROM   ranked
    WHERE  rn <= (cnt + 4)/5          -- ceils(cnt/5) without CEIL()
),
qtr_totals AS (
    /* grand total sales in each quarter (same scope) */
    SELECT t.calendar_quarter_id AS qtr,
           SUM(s.amount_sold)    AS qtr_total
    FROM sales      s
    JOIN customers  cu ON cu.cust_id = s.cust_id
    JOIN times      t  ON t.time_id  = s.time_id
    WHERE cu.cust_city IN (SELECT cust_city FROM growing_cities)
      AND s.promo_id           = 999
      AND t.calendar_quarter_id IN (1772,1776)
    GROUP BY t.calendar_quarter_id
),
product_shares AS (
    /* sales per product in each quarter (restricted to top‑20 % list) */
    SELECT pr.prod_id,
           pr.prod_name,
           COALESCE(SUM(CASE WHEN t.calendar_quarter_id = 1776 THEN s.amount_sold END),0) AS amt_2020,
           COALESCE(SUM(CASE WHEN t.calendar_quarter_id = 1772 THEN s.amount_sold END),0) AS amt_2019
    FROM sales      s
    JOIN customers  cu ON cu.cust_id = s.cust_id
    JOIN times      t  ON t.time_id  = s.time_id
    JOIN products   pr ON pr.prod_id = s.prod_id
    WHERE cu.cust_city IN (SELECT cust_city FROM growing_cities)
      AND s.promo_id           = 999
      AND t.calendar_quarter_id IN (1772,1776)
      AND s.prod_id IN (SELECT prod_id FROM top20)
    GROUP BY pr.prod_id, pr.prod_name
)
SELECT ps.prod_id,
       ps.prod_name,
       ROUND(ABS(
             100.0 * ps.amt_2020 / (SELECT qtr_total FROM qtr_totals WHERE qtr = 1776)
           - 100.0 * ps.amt_2019 / (SELECT qtr_total FROM qtr_totals WHERE qtr = 1772)
       ),4) AS pct_point_change
FROM   product_shares ps
ORDER  BY pct_point_change ASC, ps.prod_id
LIMIT 1;