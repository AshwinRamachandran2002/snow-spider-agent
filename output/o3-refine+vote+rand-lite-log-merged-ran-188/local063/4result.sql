WITH us AS (
    SELECT country_id 
    FROM   countries 
    WHERE  country_name LIKE 'United States%' 
    LIMIT 1
),
/* Q4-2019 sales per city */
q19 AS (
    SELECT cu.cust_city  AS city,
           SUM(s.amount_sold) AS amt19
    FROM   sales      s
    JOIN   customers  cu ON cu.cust_id = s.cust_id
    JOIN   times      t  ON t.time_id  = s.time_id
    WHERE  s.promo_id            = 999
      AND  cu.country_id         = (SELECT country_id FROM us)
      AND  t.calendar_quarter_id = 1772          -- Q4-2019
    GROUP BY cu.cust_city
),
/* Q4-2020 sales per city */
q20 AS (
    SELECT cu.cust_city  AS city,
           SUM(s.amount_sold) AS amt20
    FROM   sales      s
    JOIN   customers  cu ON cu.cust_id = s.cust_id
    JOIN   times      t  ON t.time_id  = s.time_id
    WHERE  s.promo_id            = 999
      AND  cu.country_id         = (SELECT country_id FROM us)
      AND  t.calendar_quarter_id = 1776          -- Q4-2020
    GROUP BY cu.cust_city
),
/* cities whose promo-999 sales grew ≥20 % */
growth_cities AS (
    SELECT q19.city
    FROM   q19
    JOIN   q20 USING (city)
    WHERE  q20.amt20 >= 1.2*q19.amt19
),
/* product sales (only growth cities, both quarters) */
core_sales AS (
    SELECT s.prod_id,
           t.calendar_quarter_id,
           SUM(s.amount_sold) AS amt
    FROM   sales      s
    JOIN   customers  cu ON cu.cust_id = s.cust_id
    JOIN   times      t  ON t.time_id  = s.time_id
    WHERE  s.promo_id            = 999
      AND  cu.country_id         = (SELECT country_id FROM us)
      AND  cu.cust_city IN (SELECT city FROM growth_cities)
      AND  t.calendar_quarter_id IN (1772,1776)
    GROUP BY s.prod_id, t.calendar_quarter_id
),
/* total of each quarter (denominator for share) */
quarter_tot AS (
    SELECT calendar_quarter_id,
           SUM(amt) AS tot_amt
    FROM   core_sales
    GROUP BY calendar_quarter_id
),
/* share of each product inside each quarter */
prod_share AS (
    SELECT cs.prod_id,
           cs.calendar_quarter_id,
           cs.amt * 1.0 / qt.tot_amt AS share
    FROM   core_sales  cs
    JOIN   quarter_tot qt USING (calendar_quarter_id)
),
/* pair the two quarters to get share change */
pair AS (
    SELECT p19.prod_id,
           p19.share AS share_2019,
           p20.share AS share_2020,
           (p20.share - p19.share) AS delta
    FROM   prod_share p19
    JOIN   prod_share p20
           ON p19.prod_id = p20.prod_id
          AND p19.calendar_quarter_id = 1772
          AND p20.calendar_quarter_id = 1776
),
/* rank products by total sales (both quarters) */
totals AS (
    SELECT prod_id,
           SUM(amt) AS grand_total
    FROM   core_sales
    GROUP BY prod_id
),
ranked AS (
    SELECT prod_id,
           grand_total,
           NTILE(5) OVER (ORDER BY grand_total DESC) AS quintile
    FROM   totals
),
top20 AS (
    SELECT prod_id
    FROM   ranked
    WHERE  quintile = 1          -- top 20 %
)
/* final result: product with smallest |Δshare| */
SELECT pair.prod_id                 AS smallest_change_prod_id,
       ROUND(pair.delta, 5)         AS pct_point_change
FROM   pair
WHERE  pair.prod_id IN (SELECT prod_id FROM top20)
ORDER  BY ABS(pair.delta) ASC
LIMIT 1;