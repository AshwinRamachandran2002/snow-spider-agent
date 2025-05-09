WITH
-- United‑States country_id
us_country AS (
    SELECT country_id
    FROM   countries
    WHERE  country_name = 'United States of America'
),
-- Q4‑2019 & Q4‑2020 “no‑promotion” sales in the U.S.
sales_us AS (
    SELECT  s.prod_id,
            s.amount_sold,
            c.cust_city,
            t.calendar_year
    FROM    sales      AS s
    JOIN    customers  AS c  ON c.cust_id   = s.cust_id
    JOIN    us_country AS u  ON u.country_id = c.country_id
    JOIN    times      AS t  ON t.time_id   = s.time_id
    WHERE   s.promo_id                = 999          -- “NO PROMOTION #”
      AND   t.calendar_quarter_number = 4
      AND   t.calendar_year           IN (2019, 2020)
),
-- city‑level totals by year
city_year AS (
    SELECT cust_city,
           calendar_year,
           SUM(amount_sold) AS amt
    FROM   sales_us
    GROUP  BY cust_city, calendar_year
),
-- cities whose 2020 sales ≥ 120 % of 2019 sales
growth_cities AS (
    SELECT c19.cust_city
    FROM   city_year c19
    JOIN   city_year c20
           ON c19.cust_city    = c20.cust_city
          AND c19.calendar_year = 2019
          AND c20.calendar_year = 2020
    WHERE  c19.amt > 0
      AND  c20.amt >= 1.20 * c19.amt
),
-- sales restricted to those growth cities
filtered_sales AS (
    SELECT *
    FROM   sales_us
    WHERE  cust_city IN (SELECT cust_city FROM growth_cities)
),
-- total (2019+2020) amount per product
prod_tot AS (
    SELECT prod_id,
           SUM(amount_sold) AS tot_amt
    FROM   filtered_sales
    GROUP  BY prod_id
),
-- keep the top 20 % products by total amount
top_products AS (
    SELECT prod_id
    FROM  (
        SELECT prod_id,
               NTILE(5) OVER (ORDER BY tot_amt DESC) AS quintile
        FROM   prod_tot
    )
    WHERE  quintile = 1
),
-- product‑year amounts
prod_year AS (
    SELECT prod_id,
           calendar_year,
           SUM(amount_sold) AS amt
    FROM   filtered_sales
    WHERE  prod_id IN (SELECT prod_id FROM top_products)
    GROUP  BY prod_id, calendar_year
),
-- overall totals (all products) per year
overall_year AS (
    SELECT calendar_year,
           SUM(amount_sold) AS tot_amt
    FROM   filtered_sales
    GROUP  BY calendar_year
),
-- pivot product amounts into 2019 vs 2020
pivot AS (
    SELECT  tp.prod_id,
            COALESCE(SUM(CASE WHEN py.calendar_year = 2019 THEN py.amt END), 0) AS amt19,
            COALESCE(SUM(CASE WHEN py.calendar_year = 2020 THEN py.amt END), 0) AS amt20
    FROM    top_products tp
    LEFT JOIN prod_year  py ON py.prod_id = tp.prod_id
    GROUP  BY tp.prod_id
),
-- bring the denominators (overall totals) into one row
denoms AS (
    SELECT MAX(CASE WHEN calendar_year = 2019 THEN tot_amt END) AS tot19,
           MAX(CASE WHEN calendar_year = 2020 THEN tot_amt END) AS tot20
    FROM   overall_year
)
SELECT
    pr.prod_name AS product,
    ROUND( (amt20 * 100.0) / d.tot20 - (amt19 * 100.0) / d.tot19 , 4) AS share_change,
    ROUND( (amt19 * 100.0) / d.tot19 , 4)                               AS share_q4_2019,
    ROUND( (amt20 * 100.0) / d.tot20 , 4)                               AS share_q4_2020
FROM        pivot p
CROSS JOIN  denoms d
JOIN        products pr ON pr.prod_id = p.prod_id
ORDER BY    share_change DESC,
            product;