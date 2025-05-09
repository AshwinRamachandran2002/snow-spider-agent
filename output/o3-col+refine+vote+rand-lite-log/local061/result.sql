WITH
-- 1.  France’s monthly product-sales in 2019
base_2019 AS (
    SELECT  t.calendar_month_number        AS month,
            s.prod_id,
            SUM(s.amount_sold)             AS amount_2019
    FROM    sales       AS s
    JOIN    customers   AS c   ON s.cust_id   = c.cust_id
    JOIN    countries   AS ct  ON c.country_id= ct.country_id
    JOIN    promotions  AS p   ON s.promo_id  = p.promo_id
    JOIN    channels    AS ch  ON s.channel_id= ch.channel_id
    JOIN    times       AS t   ON s.time_id   = t.time_id
    WHERE   ct.country_name   = 'France'
      AND   p.promo_total_id  = 1            -- required promotions
      AND   ch.channel_total_id = 1          -- required channels
      AND   t.calendar_year    = 2019
    GROUP BY t.calendar_month_number, s.prod_id
),
-- 2.  France’s monthly product-sales in 2020
base_2020 AS (
    SELECT  t.calendar_month_number        AS month,
            s.prod_id,
            SUM(s.amount_sold)             AS amount_2020
    FROM    sales       AS s
    JOIN    customers   AS c   ON s.cust_id   = c.cust_id
    JOIN    countries   AS ct  ON c.country_id= ct.country_id
    JOIN    promotions  AS p   ON s.promo_id  = p.promo_id
    JOIN    channels    AS ch  ON s.channel_id= ch.channel_id
    JOIN    times       AS t   ON s.time_id   = t.time_id
    WHERE   ct.country_name   = 'France'
      AND   p.promo_total_id  = 1
      AND   ch.channel_total_id = 1
      AND   t.calendar_year    = 2020
    GROUP BY t.calendar_month_number, s.prod_id
),
-- 3.  Growth rate from 2019 ➜ 2020 for the same product & month
growth AS (
    SELECT  b20.prod_id,
            b20.month,
            b19.amount_2019,
            b20.amount_2020,
            CASE
                 WHEN b19.amount_2019 = 0 THEN 0
                 ELSE (b20.amount_2020 - b19.amount_2019) * 1.0 / b19.amount_2019
            END                                     AS growth_rate
    FROM    base_2019 AS b19
    JOIN    base_2020 AS b20
      ON    b19.prod_id = b20.prod_id
     AND    b19.month   = b20.month
),
-- 4.  Project 2021 sales in local currency and convert to USD
projected AS (
    SELECT  g.prod_id,
            g.month,
            g.amount_2020 * (1 + g.growth_rate)               AS projected_2021_local,
            (g.amount_2020 * (1 + g.growth_rate)) / cur.to_us AS projected_2021_usd
    FROM    growth   AS g
    JOIN    currency AS cur
      ON    cur.country = 'France'
     AND    cur.year    = 2021
     AND    cur.month   = g.month
)
-- 5.  Average projected 2021 sales (USD) per month
SELECT  month,
        ROUND(AVG(projected_2021_usd), 4)  AS avg_projected_monthly_sales_usd
FROM    projected
GROUP BY month
ORDER BY month;