WITH
-- 2019 monthly totals
y19 AS (
    SELECT strftime('%m', s.time_id) AS month,
           SUM(s.amount_sold)        AS tot_2019
    FROM   sales      AS s
    JOIN   customers  AS cu ON cu.cust_id  = s.cust_id
    JOIN   countries  AS co ON co.country_id = cu.country_id
    JOIN   promotions AS p  ON p.promo_id = s.promo_id
    JOIN   channels   AS ch ON ch.channel_id = s.channel_id
    WHERE  co.country_name    = 'France'
      AND  p.promo_total_id   = 1
      AND  ch.channel_total_id= 1
      AND  strftime('%Y', s.time_id) = '2019'
    GROUP  BY month
),
-- 2020 monthly totals
y20 AS (
    SELECT strftime('%m', s.time_id) AS month,
           SUM(s.amount_sold)        AS tot_2020
    FROM   sales      AS s
    JOIN   customers  AS cu ON cu.cust_id  = s.cust_id
    JOIN   countries  AS co ON co.country_id = cu.country_id
    JOIN   promotions AS p  ON p.promo_id = s.promo_id
    JOIN   channels   AS ch ON ch.channel_id = s.channel_id
    WHERE  co.country_name    = 'France'
      AND  p.promo_total_id   = 1
      AND  ch.channel_total_id= 1
      AND  strftime('%Y', s.time_id) = '2020'
    GROUP  BY month
),
-- project 2021 totals in local currency
proj_local AS (
    SELECT y20.month,
           y20.tot_2020 * (y20.tot_2020 * 1.0 / NULLIF(y19.tot_2019,0)) AS proj_2021_local
    FROM   y20
    JOIN   y19 USING (month)
),
-- convert to USD (2020 FX assumed for 2021)
proj_usd AS (
    SELECT pl.month,
           pl.proj_2021_local * c.to_us AS proj_2021_usd
    FROM   proj_local  AS pl
    JOIN   currency    AS c
           ON  c.country = 'France'
           AND c.year    = 2020
           AND c.month   = CAST(pl.month AS INTEGER)
),
-- median of the 12 projected monthly USD values
median_cte AS (
    SELECT AVG(proj_2021_usd) AS median_val
    FROM  (
           SELECT proj_2021_usd
           FROM   proj_usd
           ORDER  BY proj_2021_usd
           LIMIT 2 - (SELECT COUNT(*) FROM proj_usd) % 2
           OFFSET (SELECT (COUNT(*) - 1) / 2 FROM proj_usd)
          )
)
SELECT ROUND(median_val, 4) AS median_projected_monthly_sales_usd_2021
FROM   median_cte;