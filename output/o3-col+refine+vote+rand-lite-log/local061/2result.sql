WITH france_id AS (            -- internal key for France
    SELECT country_id 
    FROM   countries 
    WHERE  country_name = 'France'
),

/* ----------------  2019 & 2020 monthly sales (local currency)  ---------------- */
sales_2019 AS (
    SELECT s.prod_id,
           t.calendar_month_number  AS month,
           SUM(s.amount_sold)       AS sales_2019
    FROM   sales       AS s
    JOIN   customers   AS c  ON c.cust_id = s.cust_id
    JOIN   times       AS t  ON t.time_id = s.time_id
    WHERE  c.country_id = (SELECT country_id FROM france_id)
      AND  t.calendar_year = 2019
      AND  s.channel_id IN (SELECT channel_id FROM channels   WHERE channel_total_id = 1)
      AND  s.promo_id   IN (SELECT promo_id   FROM promotions WHERE promo_total_id = 1)
    GROUP  BY s.prod_id, t.calendar_month_number
),
sales_2020 AS (
    SELECT s.prod_id,
           t.calendar_month_number  AS month,
           SUM(s.amount_sold)       AS sales_2020
    FROM   sales       AS s
    JOIN   customers   AS c  ON c.cust_id = s.cust_id
    JOIN   times       AS t  ON t.time_id = s.time_id
    WHERE  c.country_id = (SELECT country_id FROM france_id)
      AND  t.calendar_year = 2020
      AND  s.channel_id IN (SELECT channel_id FROM channels   WHERE channel_total_id = 1)
      AND  s.promo_id   IN (SELECT promo_id   FROM promotions WHERE promo_total_id = 1)
    GROUP  BY s.prod_id, t.calendar_month_number
),

/* ----------------  Growth from 2019 → 2020  ---------------- */
growth AS (
    SELECT a.prod_id,
           a.month,
           a.sales_2019,
           b.sales_2020,
           CASE 
               WHEN a.sales_2019 > 0 
               THEN (b.sales_2020 - a.sales_2019) * 1.0 / a.sales_2019
           END AS growth_rate
    FROM   sales_2019 a
    JOIN   sales_2020 b
           ON a.prod_id = b.prod_id
          AND a.month   = b.month
),

/* ----------------  2021 projection in local currency  ---------------- */
proj_2021_local AS (
    SELECT prod_id,
           month,
           sales_2020 * (1 + COALESCE(growth_rate,0)) AS projected_local
    FROM   growth
),

/* ----------------  Convert to USD using 2021 FX rates  ---------------- */
proj_2021_usd AS (
    SELECT pl.month,
           pl.projected_local * cu.to_us AS projected_usd
    FROM   proj_2021_local pl
    JOIN   currency      cu
           ON  cu.country = 'France'
           AND cu.year    = 2021
           AND cu.month   = pl.month
)

/* ----------------  Average projected 2021 monthly sales (USD)  ---------------- */
SELECT   month,
         ROUND(AVG(projected_usd), 4) AS avg_projected_monthly_sales_usd
FROM     proj_2021_usd
GROUP BY month
ORDER BY month;