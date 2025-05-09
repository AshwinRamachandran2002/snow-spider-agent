WITH
/* -------------------------------------------------
   France – monthly sales totals for 2019
--------------------------------------------------*/
m2019 AS (
    SELECT STRFTIME('%m', t.time_id) AS month,
           SUM(s.amount_sold)       AS amt2019
    FROM   sales       AS s
    JOIN   customers   AS cu ON s.cust_id  = cu.cust_id
    JOIN   countries   AS co ON cu.country_id = co.country_id
    JOIN   channels    AS ch ON s.channel_id = ch.channel_id
    JOIN   promotions  AS pr ON s.promo_id  = pr.promo_id
    JOIN   times       AS t  ON s.time_id   = t.time_id
    WHERE  co.country_name   = 'France'
      AND  pr.promo_total_id = 1
      AND  ch.channel_total_id = 1
      AND  t.calendar_year   = 2019
    GROUP  BY month
),
/* -------------------------------------------------
   France – monthly sales totals for 2020
--------------------------------------------------*/
m2020 AS (
    SELECT STRFTIME('%m', t.time_id) AS month,
           SUM(s.amount_sold)       AS amt2020
    FROM   sales       AS s
    JOIN   customers   AS cu ON s.cust_id  = cu.cust_id
    JOIN   countries   AS co ON cu.country_id = co.country_id
    JOIN   channels    AS ch ON s.channel_id = ch.channel_id
    JOIN   promotions  AS pr ON s.promo_id  = pr.promo_id
    JOIN   times       AS t  ON s.time_id   = t.time_id
    WHERE  co.country_name   = 'France'
      AND  pr.promo_total_id = 1
      AND  ch.channel_total_id = 1
      AND  t.calendar_year   = 2020
    GROUP  BY month
),
/* -------------------------------------------------
   Apply 2019→2020 growth rate to project 2021 totals
--------------------------------------------------*/
proj2021 AS (
    SELECT m2019.month,
           m2019.amt2019,
           m2020.amt2020,
           (m2020.amt2020 * 1.0 / m2019.amt2019)                 AS growth_rate,
           m2020.amt2020 * (m2020.amt2020 * 1.0 / m2019.amt2019) AS proj2021_local
    FROM   m2019
    JOIN   m2020 ON m2019.month = m2020.month
),
/* -------------------------------------------------
   Convert projected 2021 totals to USD
--------------------------------------------------*/
proj2021_usd AS (
    SELECT p.month,
           p.proj2021_local * c.to_us AS proj2021_usd
    FROM   proj2021 p
    JOIN   currency c
           ON c.country = 'France'
          AND c.year    = 2021
          AND c.month   = CAST(p.month AS INTEGER)
)
/* -------------------------------------------------
   Median of the (average) monthly projected sales
--------------------------------------------------*/
SELECT ROUND(AVG(proj2021_usd),4) AS median_monthly_projected_sales_usd
FROM (
    SELECT proj2021_usd,
           ROW_NUMBER() OVER (ORDER BY proj2021_usd) AS rn,
           COUNT(*)  OVER ()                         AS cnt
    FROM   proj2021_usd
)
WHERE rn IN ( (cnt+1)/2, (cnt+2)/2 );