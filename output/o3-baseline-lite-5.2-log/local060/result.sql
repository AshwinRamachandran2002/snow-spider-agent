WITH no_promo_sales AS (          -- United States, Q4‑2019 & Q4‑2020, sales without promotions
    SELECT  s.prod_id ,
            s.cust_id ,
            s.amount_sold ,
            t.calendar_year ,
            t.calendar_quarter_number ,
            cu.cust_city              AS city
    FROM    sales       s
    JOIN    times       t   ON t.time_id  = s.time_id
    JOIN    customers   cu  ON cu.cust_id = s.cust_id
    JOIN    countries   co  ON co.country_id = cu.country_id
    WHERE   co.country_iso_code = 'US'
      AND   s.promo_id = 999                 -- “no promotion” rows
      AND   t.calendar_quarter_number = 4    -- Q4 only
      AND   t.calendar_year IN (2019,2020)
),
-----------------------------------------------------------------
city_qtr AS (                       -- sales per city per quarter
    SELECT  city,
            calendar_year,
            SUM(amount_sold) AS amt
    FROM    no_promo_sales
    GROUP BY city, calendar_year
),
growth_cities AS (                  -- cities whose Q4‑2020 ≥ 120% Q4‑2019
    SELECT  c19.city
    FROM    city_qtr  c19
    JOIN    city_qtr  c20
           ON c19.city = c20.city
          AND c19.calendar_year = 2019
          AND c20.calendar_year = 2020
    WHERE   c20.amt >= 1.2 * c19.amt
),
-----------------------------------------------------------------
fsales AS (                         -- keep only the growing cities
    SELECT  *
    FROM    no_promo_sales
    WHERE   city IN (SELECT city FROM growth_cities)
),
-----------------------------------------------------------------
prod_tot AS (                       -- overall product sales (both years)
    SELECT  prod_id,
            SUM(amount_sold) AS amt
    FROM    fsales
    GROUP BY prod_id
),
ranked AS (                         -- rank products, keep top 20 %
    SELECT  prod_id,
            amt,
            ROW_NUMBER() OVER (ORDER BY amt DESC)          AS rn,
            COUNT(*)   OVER ()                             AS tot
    FROM    prod_tot
),
top_prod AS (
    SELECT  prod_id
    FROM    ranked
    WHERE   rn <= CAST(tot*0.20 + 0.9999 AS INTEGER)       -- ceiling(20 %)
),
-----------------------------------------------------------------
prod_qtr AS (                       -- sales of the top products per quarter
    SELECT  prod_id,
            calendar_year,
            SUM(amount_sold) AS amt
    FROM    fsales
    WHERE   prod_id IN (SELECT prod_id FROM top_prod)
    GROUP BY prod_id, calendar_year
),
tot_qtr AS (                        -- total sales (all products) per quarter
    SELECT  calendar_year,
            SUM(amount_sold) AS amt
    FROM    fsales
    GROUP BY calendar_year
),
shares AS (                         -- product share within each quarter
    SELECT  p.prod_id,
            p.calendar_year,
            p.amt*1.0 / t.amt AS share
    FROM    prod_qtr p
    JOIN    tot_qtr  t ON t.calendar_year = p.calendar_year
),
pivot AS (                          -- turn rows into columns (2019 vs 2020)
    SELECT  prod_id,
            MAX(CASE WHEN calendar_year = 2019 THEN share END) AS share_2019,
            MAX(CASE WHEN calendar_year = 2020 THEN share END) AS share_2020
    FROM    shares
    GROUP BY prod_id
)
-----------------------------------------------------------------
SELECT  p.prod_id,
        pr.prod_name,
        ROUND(p.share_2019,4) AS share_2019,
        ROUND(p.share_2020,4) AS share_2020,
        ROUND(p.share_2020 - p.share_2019,4) AS share_change
FROM    pivot      p
JOIN    products   pr ON pr.prod_id = p.prod_id
ORDER BY share_change DESC,
         p.prod_id;