WITH fr_2019 AS (
    SELECT
        s.prod_id,
        t.calendar_month_number AS month,
        SUM(s.amount_sold) AS sales_2019
    FROM sales AS s
    JOIN customers   AS c  ON s.cust_id   = c.cust_id
    JOIN countries   AS co ON c.country_id = co.country_id
    JOIN promotions  AS p  ON s.promo_id  = p.promo_id
    JOIN channels    AS ch ON s.channel_id = ch.channel_id
    JOIN times       AS t  ON s.time_id   = t.time_id
    WHERE co.country_name   = 'France'
      AND p.promo_total_id  = 1          -- only wanted promotions
      AND ch.channel_total_id = 1        -- only wanted channels
      AND t.calendar_year    = 2019
    GROUP BY s.prod_id, t.calendar_month_number
),
fr_2020 AS (
    SELECT
        s.prod_id,
        t.calendar_month_number AS month,
        SUM(s.amount_sold) AS sales_2020
    FROM sales AS s
    JOIN customers   AS c  ON s.cust_id   = c.cust_id
    JOIN countries   AS co ON c.country_id = co.country_id
    JOIN promotions  AS p  ON s.promo_id  = p.promo_id
    JOIN channels    AS ch ON s.channel_id = ch.channel_id
    JOIN times       AS t  ON s.time_id   = t.time_id
    WHERE co.country_name   = 'France'
      AND p.promo_total_id  = 1
      AND ch.channel_total_id = 1
      AND t.calendar_year    = 2020
    GROUP BY s.prod_id, t.calendar_month_number
),
growth AS (
    SELECT
        f19.prod_id,
        f19.month,
        f19.sales_2019,
        f20.sales_2020,
        CASE
            WHEN f19.sales_2019 <> 0
            THEN (f20.sales_2020 - f19.sales_2019) * 1.0 / f19.sales_2019
        END AS growth_rate
    FROM fr_2019 AS f19
    JOIN fr_2020 AS f20
      ON f19.prod_id = f20.prod_id
     AND f19.month   = f20.month
),
proj_2021 AS (
    SELECT
        prod_id,
        month,
        sales_2020 * (1 + growth_rate) AS projected_sales_2021
    FROM growth
    WHERE growth_rate IS NOT NULL
),
usd_rate AS (
    SELECT
        month,
        MAX(to_us) AS to_us               -- one row per month for France‑2021
    FROM currency
    WHERE country = 'France'
      AND year    = 2021
    GROUP BY month
)
SELECT
    u.month,
    ROUND(AVG(p.projected_sales_2021 * u.to_us), 2) AS avg_projected_sales_usd
FROM proj_2021 AS p
JOIN usd_rate  AS u ON p.month = u.month
GROUP BY u.month
ORDER BY u.month;