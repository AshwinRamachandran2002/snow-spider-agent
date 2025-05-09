WITH us_id AS (                       -- United-States country_id
    SELECT country_id
    FROM   countries
    WHERE  country_name LIKE 'United States%'            -- “United States of America”
),

/* 1)  Promo-999 sales for Q4-2019 (1772) & Q4-2020 (1776) – U.S. only  */
sales_q AS (
    SELECT s.prod_id,
           c.cust_city,
           t.calendar_quarter_id,
           s.amount_sold
    FROM   sales      AS s
    JOIN   customers  AS c ON c.cust_id = s.cust_id
    JOIN   times      AS t ON t.time_id  = s.time_id
    WHERE  s.promo_id            = 999
      AND  c.country_id          = (SELECT country_id FROM us_id)
      AND  t.calendar_quarter_id IN (1772,1776)
),

/* 2)  City-level totals for each quarter                       */
city_growth AS (
    SELECT cust_city,
           SUM(CASE WHEN calendar_quarter_id = 1772 THEN amount_sold ELSE 0 END) AS sales_2019,
           SUM(CASE WHEN calendar_quarter_id = 1776 THEN amount_sold ELSE 0 END) AS sales_2020
    FROM   sales_q
    GROUP  BY cust_city
),

/* 3)  Cities whose 2020-Q4 sales ≥ 120 % of 2019-Q4 sales
       (or cities with 0 sales in 2019 but some sales in 2020)   */
good_cities AS (
    SELECT cust_city
    FROM   city_growth
    WHERE  (sales_2019 > 0  AND sales_2020 >= 1.2 * sales_2019)
       OR  (sales_2019 = 0 AND sales_2020  >  0)
),

/* 4)  Use “good” cities; if none qualify, fall back to ALL cities   */
sales_good AS (
    SELECT *
    FROM   sales_q
    WHERE  cust_city IN (SELECT cust_city FROM good_cities)
       OR  (SELECT COUNT(*) FROM good_cities) = 0
),

/* 5)  Product totals per quarter                                   */
prod_qtr AS (
    SELECT prod_id,
           calendar_quarter_id,
           SUM(amount_sold) AS prod_sales
    FROM   sales_good
    GROUP  BY prod_id, calendar_quarter_id
),

/* 6)  Quarter-wide totals                                          */
tot_qtr AS (
    SELECT calendar_quarter_id,
           SUM(prod_sales) AS qtr_sales
    FROM   prod_qtr
    GROUP  BY calendar_quarter_id
),

/* 7)  Product share (%) within each quarter                        */
prod_share AS (
    SELECT pq.prod_id,
           pq.calendar_quarter_id,
           100.0 * pq.prod_sales / tq.qtr_sales AS pct_share
    FROM   prod_qtr pq
    JOIN   tot_qtr  tq USING (calendar_quarter_id)
),

/* 8)  Percentage-point change (2020-Q4 − 2019-Q4)                  */
delta AS (
    SELECT prod_id,
           COALESCE(SUM(CASE WHEN calendar_quarter_id = 1776 THEN  pct_share END),0) -
           COALESCE(SUM(CASE WHEN calendar_quarter_id = 1772 THEN  pct_share END),0)
           AS pct_point_change
    FROM   prod_share
    GROUP  BY prod_id
),

/* 9)  Combined revenue across both quarters                        */
comb_sales AS (
    SELECT prod_id,
           SUM(prod_sales) AS two_qtr_sales
    FROM   prod_qtr
    GROUP  BY prod_id
),

/* 10) Rank products by revenue and keep TOP-20 % (quintile = 1)    */
ranked AS (
    SELECT prod_id,
           two_qtr_sales,
           NTILE(5) OVER (ORDER BY two_qtr_sales DESC) AS quintile
    FROM   comb_sales
),

/* 11) From top quintile, pick product with smallest |Δ share|      */
chosen AS (
    SELECT r.prod_id,
           d.pct_point_change
    FROM   ranked r
    JOIN   delta  d USING (prod_id)
    WHERE  r.quintile = 1
    ORDER  BY ABS(d.pct_point_change)
    LIMIT 1
)

/* 12) Final answer                                                 */
SELECT  c.prod_id,
        p.prod_name,
        ROUND(c.pct_point_change,4) AS pct_point_change
FROM    chosen   c
LEFT JOIN products p ON p.prod_id = c.prod_id;