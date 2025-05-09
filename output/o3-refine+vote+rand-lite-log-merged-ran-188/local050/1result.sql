WITH sales_2019 AS (
    SELECT t.calendar_month_number             AS month,
           SUM(s.amount_sold)                  AS amt2019
    FROM   sales       AS s
    JOIN   customers   AS c   ON s.cust_id   = c.cust_id
    JOIN   countries   AS cn  ON c.country_id = cn.country_id
    JOIN   channels    AS ch  ON s.channel_id = ch.channel_id
    JOIN   promotions  AS p   ON s.promo_id   = p.promo_id
    JOIN   times       AS t   ON s.time_id    = t.time_id
    WHERE  cn.country_name      = 'France'
      AND  ch.channel_total_id  = 1
      AND  p.promo_total_id     = 1
      AND  t.calendar_year      = 2019
    GROUP  BY t.calendar_month_number
),
sales_2020 AS (
    SELECT t.calendar_month_number             AS month,
           SUM(s.amount_sold)                  AS amt2020
    FROM   sales       AS s
    JOIN   customers   AS c   ON s.cust_id   = c.cust_id
    JOIN   countries   AS cn  ON c.country_id = cn.country_id
    JOIN   channels    AS ch  ON s.channel_id = ch.channel_id
    JOIN   promotions  AS p   ON s.promo_id   = p.promo_id
    JOIN   times       AS t   ON s.time_id    = t.time_id
    WHERE  cn.country_name      = 'France'
      AND  ch.channel_total_id  = 1
      AND  p.promo_total_id     = 1
      AND  t.calendar_year      = 2020
    GROUP  BY t.calendar_month_number
),
proj_local AS (
    SELECT s20.month,
           CASE 
               WHEN s19.amt2019 > 0 
               THEN s20.amt2020 * (s20.amt2020 / s19.amt2019)
           END                                       AS proj_2021_local
    FROM   sales_2019  AS s19
    JOIN   sales_2020  AS s20 USING (month)
),
proj_usd AS (
    SELECT pl.month,
           pl.proj_2021_local / c.to_us           AS proj_2021_usd
    FROM   proj_local  AS pl
    JOIN   currency    AS c
           ON  c.country = 'France'
           AND c.year    = 2021
           AND c.month   = pl.month
),
ordered AS (
    SELECT proj_2021_usd,
           ROW_NUMBER() OVER (ORDER BY proj_2021_usd) AS rn,
           COUNT(*)  OVER ()                          AS cnt
    FROM   proj_usd
)
SELECT AVG(proj_2021_usd) AS median_projected_2021_usd
FROM   ordered
WHERE  rn IN (cnt/2, cnt/2 + 1);