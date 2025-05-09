WITH base AS (
    /* France sales in 2019‑2020 that belong to promo_total_id = 1 and channel_total_id = 1 */
    SELECT  s.amount_sold  AS amt,
            s.time_id
    FROM   sales      AS s
    JOIN   customers  AS c   ON c.cust_id   = s.cust_id
    JOIN   countries  AS co  ON co.country_id = c.country_id
    JOIN   promotions AS p   ON p.promo_id  = s.promo_id
    JOIN   channels   AS ch  ON ch.channel_id = s.channel_id
    WHERE  co.country_name   = 'France'
      AND  p.promo_total_id  = 1
      AND  ch.channel_total_id = 1
      AND  strftime('%Y', s.time_id) IN ('2019','2020')
),
/* annual totals to obtain the 2019‑2020 growth factor */
year_totals AS (
    SELECT strftime('%Y', time_id) AS yr,
           SUM(amt)                AS total
    FROM   base
    GROUP  BY yr
),
growth AS (
    SELECT (SELECT total FROM year_totals WHERE yr = '2020') * 1.0 /
           (SELECT total FROM year_totals WHERE yr = '2019') AS g
),
/* average sale amount per month in 2020 */
month_avg_2020 AS (
    SELECT CAST(strftime('%m', time_id) AS INTEGER) AS month,
           AVG(amt)                               AS avg_amt_2020
    FROM   base
    WHERE  strftime('%Y', time_id) = '2020'
    GROUP  BY month
),
/* project 2021 local‑currency monthly averages */
projected_2021_local AS (
    SELECT m.month,
           m.avg_amt_2020 * g.g AS proj_amt
    FROM   month_avg_2020 AS m
    CROSS  JOIN growth     AS g
),
/* convert projected amounts to USD */
projected_2021_usd AS (
    SELECT p.month,
           p.proj_amt * cu.to_us AS proj_usd
    FROM   projected_2021_local AS p
    JOIN   currency             AS cu
           ON cu.country = 'France'
          AND cu.year    = 2021
          AND cu.month   = p.month
),
/* order the 12 monthly averages to compute the median */
ordered AS (
    SELECT proj_usd,
           ROW_NUMBER() OVER (ORDER BY proj_usd) AS rn,
           COUNT(*)    OVER ()                   AS cnt
    FROM   projected_2021_usd
)
SELECT AVG(proj_usd) AS median_monthly_projected_sales_usd_2021
FROM   ordered
WHERE  rn IN ( (cnt + 1) / 2, (cnt + 2) / 2 );