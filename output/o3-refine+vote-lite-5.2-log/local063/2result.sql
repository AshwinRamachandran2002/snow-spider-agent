/*  Product (promo_id = 999, U.S. only) whose share‑of‑sales changed the least,   
    restricting to cities whose overall sales grew ≥20 % from 2019‑Q4 to 2020‑Q4  */

WITH qualifying_cities AS (            -- U.S. cities whose TOTAL sales rose ≥20 %
    SELECT  c.cust_city
    FROM    sales      s
    JOIN    customers  c  ON c.cust_id   = s.cust_id
    JOIN    countries  co ON co.country_id = c.country_id
    JOIN    times      t  ON t.time_id   = s.time_id
    WHERE   co.country_iso_code = 'US'           -- United States
      AND   t.calendar_quarter_id IN (1772,1776) -- 1772 = 2019‑Q4, 1776 = 2020‑Q4
    GROUP BY c.cust_city
    HAVING  SUM(CASE WHEN t.calendar_quarter_id = 1772 THEN s.amount_sold ELSE 0 END) > 0
       AND  SUM(CASE WHEN t.calendar_quarter_id = 1776 THEN s.amount_sold ELSE 0 END)
            >= 1.20 * SUM(CASE WHEN t.calendar_quarter_id = 1772 THEN s.amount_sold ELSE 0 END)
),

product_quarter_sales AS (             -- promo‑999 sales by product & quarter
    SELECT  s.prod_id,
            t.calendar_quarter_id,
            SUM(s.amount_sold) AS amt
    FROM    sales      s
    JOIN    customers  c  ON c.cust_id    = s.cust_id
    JOIN    countries  co ON co.country_id = c.country_id
    JOIN    times      t  ON t.time_id    = s.time_id
    WHERE   s.promo_id          = 999
      AND   co.country_iso_code = 'US'
      AND   t.calendar_quarter_id IN (1772,1776)
      AND   c.cust_city IN (SELECT cust_city FROM qualifying_cities)
    GROUP BY s.prod_id, t.calendar_quarter_id
),

total_quarter_amt AS (                 -- total promo‑999 amount each quarter
    SELECT  calendar_quarter_id,
            SUM(amt) AS total_amt
    FROM    product_quarter_sales
    GROUP BY calendar_quarter_id
),

product_pivot AS (                     -- amounts per product in both quarters
    SELECT  prod_id,
            COALESCE( SUM(CASE WHEN calendar_quarter_id = 1772 THEN amt END), 0 ) 
                 AS amt_2019_q4,
            COALESCE( SUM(CASE WHEN calendar_quarter_id = 1776 THEN amt END), 0 ) 
                 AS amt_2020_q4
    FROM    product_quarter_sales
    GROUP BY prod_id
),

product_share AS (                     -- share of quarter total & share change
    SELECT  pp.prod_id,
            pp.amt_2019_q4,
            pp.amt_2020_q4,
            pp.amt_2019_q4 * 1.0 /
              (SELECT total_amt FROM total_quarter_amt WHERE calendar_quarter_id = 1772)
              AS share_2019,
            pp.amt_2020_q4 * 1.0 /
              (SELECT total_amt FROM total_quarter_amt WHERE calendar_quarter_id = 1776)
              AS share_2020,
            (pp.amt_2019_q4 + pp.amt_2020_q4) AS total_two_qtrs
    FROM    product_pivot pp
),

ranked_products AS (                   -- divide into 5 equal tiles by sales
    SELECT  ps.*,
            NTILE(5) OVER (ORDER BY total_two_qtrs DESC) AS tile
    FROM    product_share ps
),

top_20_percent AS (                    -- keep only top 20 % (tile = 1)
    SELECT  *,
            ABS(share_2020 - share_2019) AS share_change
    FROM    ranked_products
    WHERE   tile = 1
),

min_change AS (                        -- smallest change among those products
    SELECT MIN(share_change) AS min_share_change
    FROM   top_20_percent
)

SELECT  tp.prod_id,
        p.prod_name,
        ROUND(tp.share_change,4) AS share_change
FROM    top_20_percent tp
JOIN    min_change mc ON tp.share_change = mc.min_share_change
JOIN    products   p  ON p.prod_id      = tp.prod_id;