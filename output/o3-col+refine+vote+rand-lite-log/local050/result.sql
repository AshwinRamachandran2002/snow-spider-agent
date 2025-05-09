WITH sales_2019 AS (          -- average monthly sales in USD for 2019
    SELECT strftime('%m', s.time_id)         AS mon,
           AVG(s.amount_sold / NULLIF(cu.to_us,0)) AS avg_usd_2019
    FROM   sales       AS s
    JOIN   customers   USING (cust_id)
    JOIN   countries   USING (country_id)
    JOIN   times       AS t   ON t.time_id = s.time_id
    JOIN   promotions  USING (promo_id)
    JOIN   channels    USING (channel_id)
    JOIN   currency    AS cu
           ON cu.country = 'France'
          AND cu.year    = t.calendar_year
          AND cu.month   = t.calendar_month_number
    WHERE  countries.country_name = 'France'
      AND  t.calendar_year        = 2019
      AND  promotions.promo_total_id = 1
      AND  channels.channel_total_id = 1
    GROUP  BY mon
),
sales_2020 AS (          -- average monthly sales in USD for 2020
    SELECT strftime('%m', s.time_id)         AS mon,
           AVG(s.amount_sold / NULLIF(cu.to_us,0)) AS avg_usd_2020
    FROM   sales       AS s
    JOIN   customers   USING (cust_id)
    JOIN   countries   USING (country_id)
    JOIN   times       AS t   ON t.time_id = s.time_id
    JOIN   promotions  USING (promo_id)
    JOIN   channels    USING (channel_id)
    JOIN   currency    AS cu
           ON cu.country = 'France'
          AND cu.year    = t.calendar_year
          AND cu.month   = t.calendar_month_number
    WHERE  countries.country_name = 'France'
      AND  t.calendar_year        = 2020
      AND  promotions.promo_total_id = 1
      AND  channels.channel_total_id = 1
    GROUP  BY mon
),
proj_2021 AS (           -- project 2021 monthly averages using 19→20 growth rate
    SELECT s20.mon,
           CASE
               WHEN s19.avg_usd_2019 > 0
               THEN s20.avg_usd_2020 * (s20.avg_usd_2020 / s19.avg_usd_2019)
           END AS proj_usd_2021
    FROM   sales_2020 s20
    JOIN   sales_2019 s19 USING (mon)
),
ranked AS (              -- rank the projected months for median
    SELECT proj_usd_2021,
           ROW_NUMBER() OVER (ORDER BY proj_usd_2021) AS rn,
           COUNT(*)  OVER ()                          AS cnt
    FROM   proj_2021
)
SELECT ROUND(AVG(proj_usd_2021),4) AS median_projected_2021_usd
FROM   ranked
WHERE  rn IN ( (cnt+1)/2, (cnt+2)/2 );   -- picks the two middle rows for even count