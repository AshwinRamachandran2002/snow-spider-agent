WITH france_country AS (
    SELECT country_id
    FROM countries
    WHERE country_name = 'France'
),
-- All France sales that meet the promo and channel filters
sales_filtered AS (
    SELECT s.amount_sold,
           s.time_id
    FROM   sales      AS s
    JOIN   customers  AS c   ON s.cust_id  = c.cust_id
    JOIN   promotions AS p   ON s.promo_id = p.promo_id
    JOIN   channels   AS ch  ON s.channel_id = ch.channel_id
    WHERE  c.country_id IN (SELECT country_id FROM france_country)
      AND  p.promo_total_id   = 1
      AND  ch.channel_total_id = 1
),
-- Monthly average for 2019
avg_2019 AS (
    SELECT CAST(substr(time_id,6,2) AS INTEGER) AS month,
           AVG(amount_sold)                     AS avg19
    FROM   sales_filtered
    WHERE  substr(time_id,1,4) = '2019'
    GROUP  BY month
),
-- Monthly average for 2020
avg_2020 AS (
    SELECT CAST(substr(time_id,6,2) AS INTEGER) AS month,
           AVG(amount_sold)                     AS avg20
    FROM   sales_filtered
    WHERE  substr(time_id,1,4) = '2020'
    GROUP  BY month
),
-- Growth rate 2019 ➜ 2020 and projected 2021 (local currency)
projected_2021_local AS (
    SELECT a20.month,
           a20.avg20,
           a19.avg19,
           a20.avg20 * 1.0 / a19.avg19                   AS growth_rate,
           a20.avg20 * (a20.avg20 * 1.0 / a19.avg19)     AS proj2021_local
    FROM   avg_2020 a20
    JOIN   avg_2019 a19 USING (month)
    WHERE  a19.avg19 IS NOT NULL
       AND a19.avg19 <> 0
),
-- Convert projected 2021 averages to USD
projected_2021_usd AS (
    SELECT p.month,
           p.proj2021_local * IFNULL(cur.to_us,1.0) AS proj_usd
    FROM   projected_2021_local p
    LEFT   JOIN currency cur
           ON cur.country = 'France'
          AND cur.year    = 2021
          AND cur.month   = p.month
),
-- Rank the monthly projected USD values to compute the median
ordered_vals AS (
    SELECT proj_usd,
           ROW_NUMBER() OVER (ORDER BY proj_usd) AS rn,
           COUNT(*)    OVER ()                   AS cnt
    FROM   projected_2021_usd
)
SELECT ROUND(AVG(proj_usd),4) AS median_projected_avg_monthly_sales_2021_usd
FROM   ordered_vals
WHERE  rn IN ((cnt+1)/2, (cnt+2)/2);