WITH city_growth AS (
    /* 1.  Cities in the U.S. whose promo‑999 sales grew ≥20% from Q4‑2019 to Q4‑2020 */
    SELECT  c.cust_city                       AS city,
            SUM(CASE WHEN t.calendar_quarter_id = 1772 THEN s.amount_sold END) AS sales_2019,
            SUM(CASE WHEN t.calendar_quarter_id = 1776 THEN s.amount_sold END) AS sales_2020
    FROM    sales      s
    JOIN    customers  c   ON s.cust_id  = c.cust_id
    JOIN    countries  co  ON c.country_id = co.country_id
    JOIN    times      t   ON s.time_id  = t.time_id
    WHERE   co.country_iso_code = 'US'          -- United States
      AND   s.promo_id          = 999
      AND   t.calendar_quarter_id IN (1772,1776)/* Q4‑2019 & Q4‑2020 */
    GROUP BY c.cust_city
    HAVING  sales_2019 > 0
       AND  sales_2020 >= 1.2 * sales_2019
),
product_sales AS (
    /* 2.  Total promo‑999 sales (both quarters) for each product in those cities */
    SELECT  s.prod_id,
            SUM(s.amount_sold) AS total_sales
    FROM    sales      s
    JOIN    customers  c   ON s.cust_id  = c.cust_id
    JOIN    countries  co  ON c.country_id = co.country_id
    JOIN    times      t   ON s.time_id  = t.time_id
    JOIN    city_growth cg ON cg.city     = c.cust_city
    WHERE   co.country_iso_code = 'US'
      AND   s.promo_id          = 999
      AND   t.calendar_quarter_id IN (1772,1776)
    GROUP BY s.prod_id
),
top_products AS (
    /* 3.  Keep only products in the top 20 % of total sales */
    SELECT  prod_id, total_sales
    FROM   (
        SELECT prod_id,
               total_sales,
               ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rn,
               COUNT(*)    OVER ()                          AS cnt
        FROM   product_sales
    )
    WHERE rn <= CAST(cnt * 0.2 + 0.9999 AS INT)             -- top 20 %
),
product_quarter_sales AS (
    /* 4.  Sales per product per quarter, but only for the top‑20 % products */
    SELECT  s.prod_id,
            t.calendar_quarter_id AS qtr,
            SUM(s.amount_sold)    AS sales
    FROM    sales      s
    JOIN    customers  c   ON s.cust_id  = c.cust_id
    JOIN    countries  co  ON c.country_id = co.country_id
    JOIN    times      t   ON s.time_id  = t.time_id
    JOIN    city_growth cg ON cg.city     = c.cust_city
    WHERE   co.country_iso_code = 'US'
      AND   s.promo_id          = 999
      AND   t.calendar_quarter_id IN (1772,1776)
      AND   s.prod_id IN (SELECT prod_id FROM top_products)
    GROUP BY s.prod_id, t.calendar_quarter_id
),
quarter_totals AS (
    /* 5.  Total sales for each quarter (all products) in the filtered cities */
    SELECT  t.calendar_quarter_id AS qtr,
            SUM(s.amount_sold)    AS total_sales
    FROM    sales      s
    JOIN    customers  c   ON s.cust_id  = c.cust_id
    JOIN    countries  co  ON c.country_id = co.country_id
    JOIN    times      t   ON s.time_id  = t.time_id
    JOIN    city_growth cg ON cg.city     = c.cust_city
    WHERE   co.country_iso_code = 'US'
      AND   s.promo_id          = 999
      AND   t.calendar_quarter_id IN (1772,1776)
    GROUP BY t.calendar_quarter_id
),
product_share AS (
    /* 6.  Share of each product in total sales for each quarter */
    SELECT  pqs.prod_id,
            SUM(CASE WHEN qtr = 1772 THEN sales END) AS sales_2019,
            SUM(CASE WHEN qtr = 1776 THEN sales END) AS sales_2020
    FROM    product_quarter_sales pqs
    GROUP BY pqs.prod_id
),
share_change AS (
    /* 7.  Percentage‑point change in share between the two quarters */
    SELECT  ps.prod_id,
            ABS( (ps.sales_2020 * 1.0 / qt20.total_sales) -
                 (ps.sales_2019 * 1.0 / qt19.total_sales) ) AS share_diff
    FROM    product_share ps
    JOIN    quarter_totals qt19 ON qt19.qtr = 1772
    JOIN    quarter_totals qt20 ON qt20.qtr = 1776
)
SELECT      pr.prod_id,
            pr.prod_name
FROM        share_change      sc
JOIN        products          pr ON pr.prod_id = sc.prod_id
ORDER BY    sc.share_diff ASC, pr.prod_id
LIMIT 1;