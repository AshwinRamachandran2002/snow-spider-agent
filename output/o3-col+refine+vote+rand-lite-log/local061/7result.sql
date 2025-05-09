WITH france AS (
    SELECT country_id 
    FROM countries 
    WHERE country_name = 'France'
),
base_sales AS (          -- 2019-2020 monthly sales per product (France only)
    SELECT  s.prod_id,
            strftime('%Y', s.time_id) AS yr,
            strftime('%m', s.time_id) AS mon,
            SUM(s.amount_sold)       AS amt
    FROM   sales       AS s
    JOIN   customers   AS c  ON c.cust_id  = s.cust_id
    JOIN   promotions  AS p  ON p.promo_id = s.promo_id  AND p.promo_total_id   = 1
    JOIN   channels    AS ch ON ch.channel_id = s.channel_id AND ch.channel_total_id = 1
    WHERE  c.country_id = (SELECT country_id FROM france)
      AND  strftime('%Y', s.time_id) IN ('2019','2020')
    GROUP  BY s.prod_id, yr, mon
),
pivot AS (               -- put 2019 & 2020 amounts side-by-side
    SELECT prod_id,
           mon,
           SUM(CASE WHEN yr='2019' THEN amt END) AS amt2019,
           SUM(CASE WHEN yr='2020' THEN amt END) AS amt2020
    FROM   base_sales
    GROUP  BY prod_id, mon
),
projection AS (          -- project 2021 EUR sales using growth (2020 vs 2019)
    SELECT prod_id,
           mon,
           CASE WHEN amt2019 > 0
                THEN (amt2020 - amt2019) / amt2019
                ELSE 0
           END                                           AS growth_rate,
           amt2020 * (1 + CASE WHEN amt2019 > 0
                               THEN (amt2020 - amt2019) / amt2019
                               ELSE 0
                          END)                           AS proj_2021_eur
    FROM   pivot
),
fx_2021 AS (             -- 2021 EUR-to-USD rates for France
    SELECT month AS mon, to_us
    FROM   currency
    WHERE  country = 'France'
      AND  year    = 2021
),
converted AS (           -- convert projected 2021 EUR to USD
    SELECT p.prod_id,
           p.mon,
           p.proj_2021_eur * f.to_us  AS proj_2021_usd
    FROM   projection AS p
    JOIN   fx_2021    AS f USING (mon)
)
SELECT   mon                                   AS month_2021,
         ROUND(AVG(proj_2021_usd),4)           AS avg_projected_sales_usd
FROM     converted
GROUP BY mon
ORDER BY mon;