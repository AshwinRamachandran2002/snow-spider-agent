WITH france AS (
    SELECT country_id
    FROM countries
    WHERE country_name = 'France'
),
filtered_sales AS (
    SELECT s.prod_id,
           s.time_id,
           s.amount_sold
    FROM   sales      s
    JOIN   customers  c  ON c.cust_id  = s.cust_id
    JOIN   france     f  ON f.country_id = c.country_id
    JOIN   promotions pr ON pr.promo_id = s.promo_id
                        AND pr.promo_total_id = 1
    JOIN   channels   ch ON ch.channel_id = s.channel_id
                        AND ch.channel_total_id = 1
),
sales_year_mon AS (
    SELECT t.calendar_year         AS yr,
           t.calendar_month_number AS mon,
           fs.prod_id              AS prod,
           SUM(fs.amount_sold)     AS amt
    FROM   filtered_sales fs
    JOIN   times t ON t.time_id = fs.time_id
    WHERE  t.calendar_year IN (2019, 2020)
    GROUP BY yr, mon, prod
),
growth AS (
    SELECT a.mon,
           a.prod,
           a.amt                       AS amt_2019,
           b.amt                       AS amt_2020,
           CASE WHEN a.amt <> 0 
                THEN (b.amt - a.amt) * 1.0 / a.amt 
                ELSE NULL 
           END                         AS growth_rate
    FROM   sales_year_mon a
    JOIN   sales_year_mon b
           ON a.prod = b.prod
          AND a.mon  = b.mon
          AND a.yr   = 2019
          AND b.yr   = 2020
),
projection AS (
    SELECT g.mon,
           g.prod,
           g.amt_2020 * (1 + COALESCE(g.growth_rate,0)) AS projected_local
    FROM   growth g
),
fx AS (
    SELECT month AS mon,
           to_us
    FROM   currency
    WHERE  country = 'France'
      AND  year    = 2021
)
SELECT p.mon AS month,
       ROUND(AVG(p.projected_local / f.to_us), 4) AS avg_projected_sales_usd
FROM   projection p
JOIN   fx        f ON f.mon = p.mon
GROUP BY p.mon
ORDER BY p.mon;