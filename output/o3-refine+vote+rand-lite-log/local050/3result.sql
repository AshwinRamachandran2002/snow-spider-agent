WITH sales_fr AS (
    SELECT  s.amount_sold,
            t.calendar_year  AS yr,
            t.calendar_month_number AS mn
    FROM   sales          AS s
           JOIN customers   AS cu  ON cu.cust_id   = s.cust_id
           JOIN countries   AS co  ON co.country_id = cu.country_id
           JOIN promotions  AS pr  ON pr.promo_id  = s.promo_id
           JOIN channels    AS ch  ON ch.channel_id = s.channel_id
           JOIN times       AS t   ON t.time_id    = s.time_id
    WHERE  co.country_name      = 'France'
      AND  pr.promo_total_id    = 1          -- keep only “total” promos
      AND  ch.channel_total_id  = 1          -- keep only “total” channels
      AND  t.calendar_year IN (2019, 2020)   -- years used for the projection
),
avg_monthly AS (                     -- average monthly sales for 2019 & 2020
    SELECT yr,
           mn,
           AVG(amount_sold) AS avg_amt
    FROM   sales_fr
    GROUP  BY yr, mn
),
growth_proj AS (                     -- growth factor 2019➜2020, project 2021
    SELECT m2020.mn                        AS month,
           m2019.avg_amt                   AS avg_2019,
           m2020.avg_amt                   AS avg_2020,
           CASE 
                WHEN m2019.avg_amt = 0 THEN NULL
                ELSE m2020.avg_amt / m2019.avg_amt 
           END                              AS growth_factor,
           CASE 
                WHEN m2019.avg_amt = 0 THEN NULL
                ELSE m2020.avg_amt * (m2020.avg_amt / m2019.avg_amt)
           END                              AS proj_2021_local
    FROM   avg_monthly  AS m2019
           JOIN avg_monthly AS m2020
                 ON m2019.mn  = m2020.mn
                AND m2019.yr  = 2019
                AND m2020.yr  = 2020
),
proj_usd AS (                         -- convert the 2021 projection to USD
    SELECT g.month,
           g.proj_2021_local * IFNULL(cur.to_us,1) AS proj_2021_usd
    FROM   growth_proj AS g
           LEFT JOIN currency AS cur
                  ON cur.country = 'France'
                 AND cur.year    = 2021
                 AND cur.month   = g.month
),
ordered_vals AS (                     -- order the 12 monthly projections
    SELECT proj_2021_usd                             AS val,
           ROW_NUMBER() OVER (ORDER BY proj_2021_usd) AS rn,
           COUNT(*)    OVER ()                        AS cnt
    FROM   proj_usd
)
SELECT ROUND(AVG(val),4) AS median_monthly_projected_sales_usd_2021
FROM   ordered_vals
WHERE  rn IN ( (cnt+1)/2, (cnt+2)/2 );