WITH good_channels AS (
    SELECT channel_id
    FROM channels
    WHERE channel_total_id = 1
),
good_promos AS (
    SELECT promo_id
    FROM promotions
    WHERE promo_total_id = 1
),
y19 AS (                                            -- 2019 totals per product & month
    SELECT strftime('%m', s.time_id) AS mon,
           s.prod_id,
           SUM(s.amount_sold)        AS amt_2019
    FROM   sales      s
    JOIN   customers  c  ON c.cust_id   = s.cust_id
    JOIN   countries  co ON co.country_id = c.country_id
    WHERE  co.country_name = 'France'
      AND  s.channel_id    IN (SELECT channel_id FROM good_channels)
      AND  s.promo_id      IN (SELECT promo_id   FROM good_promos)
      AND  strftime('%Y', s.time_id) = '2019'
    GROUP BY mon, s.prod_id
),
y20 AS (                                            -- 2020 totals per product & month
    SELECT strftime('%m', s.time_id) AS mon,
           s.prod_id,
           SUM(s.amount_sold)        AS amt_2020
    FROM   sales      s
    JOIN   customers  c  ON c.cust_id   = s.cust_id
    JOIN   countries  co ON co.country_id = c.country_id
    WHERE  co.country_name = 'France'
      AND  s.channel_id    IN (SELECT channel_id FROM good_channels)
      AND  s.promo_id      IN (SELECT promo_id   FROM good_promos)
      AND  strftime('%Y', s.time_id) = '2020'
    GROUP BY mon, s.prod_id
),
growth AS (                                         -- growth & 2021 local-currency projection
    SELECT y19.mon,
           CAST(y19.mon AS INTEGER)                      AS mon_int,
           y19.prod_id,
           y19.amt_2019,
           y20.amt_2020,
           (y20.amt_2020 - y19.amt_2019) /
           NULLIF(y19.amt_2019,0)                       AS growth_rate,
           y20.amt_2020 *
           (1 + (y20.amt_2020 - y19.amt_2019) /
                NULLIF(y19.amt_2019,0))                 AS proj_2021_local
    FROM   y19
    JOIN   y20 USING (mon, prod_id)
)
SELECT printf('%02d', g.mon_int)                         AS month,
       ROUND(AVG(g.proj_2021_local * cu.to_us), 4)       AS avg_projected_sales_usd
FROM   growth   g
JOIN   currency cu
       ON  cu.country = 'France'
       AND cu.year    = 2021
       AND cu.month   = g.mon_int
GROUP  BY g.mon_int
ORDER  BY g.mon_int;