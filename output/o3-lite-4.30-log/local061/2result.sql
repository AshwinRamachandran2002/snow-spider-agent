WITH france_sales AS (
    SELECT
        s.prod_id,
        t.calendar_month_number AS month,
        t.calendar_year         AS year,
        SUM(s.amount_sold)      AS amount_sold
    FROM   sales      AS s
    JOIN   customers  AS c   ON c.cust_id     = s.cust_id
    JOIN   countries  AS co  ON co.country_id = c.country_id
    JOIN   promotions AS p   ON p.promo_id    = s.promo_id
    JOIN   channels   AS ch  ON ch.channel_id = s.channel_id
    JOIN   times      AS t   ON t.time_id     = s.time_id
    WHERE  co.country_name     = 'France'
      AND  p.promo_total_id    = 1
      AND  ch.channel_total_id = 1
      AND  t.calendar_year IN (2019, 2020)
    GROUP BY s.prod_id, t.calendar_month_number, t.calendar_year
),
year2019 AS (
    SELECT prod_id, month, amount_sold AS total_2019
    FROM   france_sales
    WHERE  year = 2019
),
year2020 AS (
    SELECT prod_id, month, amount_sold AS total_2020
    FROM   france_sales
    WHERE  year = 2020
),
growth AS (
    SELECT
        y20.prod_id,
        y20.month,
        y20.total_2020,
        (y20.total_2020 - COALESCE(y19.total_2019,0)) * 1.0 /
        NULLIF(COALESCE(y19.total_2019,0),0) AS growth_rate
    FROM year2020 y20
    LEFT JOIN year2019 y19
           ON y19.prod_id = y20.prod_id
          AND y19.month   = y20.month
),
proj2021 AS (
    SELECT
        prod_id,
        month,
        total_2020 * (1 + COALESCE(growth_rate,0)) AS projected_local
    FROM   growth
),
proj2021_usd AS (
    SELECT
        p.month,
        p.projected_local / cu.to_us AS projected_usd
    FROM   proj2021 p
    JOIN   currency cu
           ON cu.country = 'France'
          AND cu.year    = 2021
          AND cu.month   = p.month
)
SELECT
    month,
    ROUND(AVG(projected_usd),4) AS avg_projected_sales_usd
FROM   proj2021_usd
GROUP BY month
ORDER BY month;