WITH
/* 1.  Cities in the U.S. whose Q4‑2020 sales (no promotion) were at least 20 % higher than in Q4‑2019 */
city_growth AS (
    SELECT
        c.cust_city                                           AS city,
        SUM(CASE WHEN t.calendar_year = 2019
                 THEN s.amount_sold END)                      AS sales_2019,
        SUM(CASE WHEN t.calendar_year = 2020
                 THEN s.amount_sold END)                      AS sales_2020
    FROM   sales      s
    JOIN   customers  c  ON c.cust_id   = s.cust_id
    JOIN   countries  co ON co.country_id = c.country_id
    JOIN   times      t  ON t.time_id    = s.time_id
    WHERE  co.country_name LIKE 'United States%'          -- U.S. only
      AND  s.promo_id            = 999                    -- “no promotion”
      AND  t.calendar_quarter_number = 4                  -- Q4
      AND  t.calendar_year IN (2019, 2020)
    GROUP  BY c.cust_city
    HAVING sales_2019 > 0
       AND sales_2020 >= 1.20 * sales_2019
),
/* 2.  Sales of every product (still “no promotion”) inside the growing cities */
product_sales AS (
    SELECT
        s.prod_id,
        SUM(CASE WHEN t.calendar_year = 2019
                 THEN s.amount_sold END)      AS sales_2019,
        SUM(CASE WHEN t.calendar_year = 2020
                 THEN s.amount_sold END)      AS sales_2020,
        SUM(s.amount_sold)                    AS total_sales
    FROM   sales      s
    JOIN   customers  c  ON c.cust_id   = s.cust_id
    JOIN   countries  co ON co.country_id = c.country_id
    JOIN   times      t  ON t.time_id    = s.time_id
    WHERE  co.country_name LIKE 'United States%'
      AND  s.promo_id            = 999
      AND  t.calendar_quarter_number = 4
      AND  t.calendar_year IN (2019, 2020)
      AND  c.cust_city IN (SELECT city FROM city_growth)
    GROUP BY s.prod_id
),
/* 3.  Keep only the top 20 % of products, ranked by combined Q4‑2019 + Q4‑2020 sales */
top_products AS (
    SELECT
        ps.*,
        CUME_DIST() OVER (ORDER BY ps.total_sales DESC) AS cd          -- cumulative share
    FROM product_sales ps
    WHERE ps.total_sales > 0
),
/* 4.  Totals for share calculation */
totals AS (
    SELECT
        SUM(CASE WHEN t.calendar_year = 2019 THEN s.amount_sold END) AS total_2019,
        SUM(CASE WHEN t.calendar_year = 2020 THEN s.amount_sold END) AS total_2020
    FROM   sales      s
    JOIN   customers  c  ON c.cust_id   = s.cust_id
    JOIN   countries  co ON co.country_id = c.country_id
    JOIN   times      t  ON t.time_id    = s.time_id
    WHERE  co.country_name LIKE 'United States%'
      AND  s.promo_id            = 999
      AND  t.calendar_quarter_number = 4
      AND  t.calendar_year IN (2019, 2020)
      AND  c.cust_city IN (SELECT city FROM city_growth)
)
/* 5.  Final result */
SELECT
    tp.prod_id,
    ROUND(tp.sales_2019 / totals.total_2019, 4) AS share_2019,
    ROUND(tp.sales_2020 / totals.total_2020, 4) AS share_2020,
    ROUND(tp.sales_2020 / totals.total_2020
        - tp.sales_2019 / totals.total_2019, 4) AS share_change
FROM   top_products tp
CROSS  JOIN totals
WHERE  tp.cd <= 0.20                       -- top 20 %
ORDER  BY share_change DESC,
          tp.prod_id;