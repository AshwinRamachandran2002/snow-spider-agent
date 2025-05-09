WITH sales_france AS (
    SELECT
        t.calendar_year         AS year ,
        t.calendar_month_number AS month ,
        s.amount_sold ,
        COALESCE(cu.to_us,1)    AS to_us
    FROM sales       AS s
    JOIN customers   AS c   ON s.cust_id   = c.cust_id
    JOIN countries   AS co  ON c.country_id= co.country_id
    JOIN promotions  AS p   ON s.promo_id  = p.promo_id
    JOIN channels    AS ch  ON s.channel_id= ch.channel_id
    JOIN times       AS t   ON s.time_id   = t.time_id
    LEFT JOIN currency cu   ON cu.country  = co.country_name
                           AND cu.year     = t.calendar_year
                           AND cu.month    = t.calendar_month_number
    WHERE co.country_name     = 'France'
      AND p.promo_total_id    = 1          -- requested promotion filter
      AND ch.channel_total_id = 1          -- requested channel filter
      AND t.calendar_year IN (2019,2020)   -- only 2019‑2020 data
), monthly_totals AS (                       -- total sales per month (in USD)
    SELECT
        year,
        month,
        SUM(amount_sold * to_us) AS monthly_sales_usd
    FROM sales_france
    GROUP BY year,month
), yearly_avg AS (                           -- average monthly sales per year
    SELECT
        year,
        AVG(monthly_sales_usd) AS avg_monthly_sales_usd
    FROM monthly_totals
    GROUP BY year
), growth_cte AS (                           -- growth factor 2019 ➜ 2020
    SELECT
        (SELECT avg_monthly_sales_usd FROM yearly_avg WHERE year = 2020) * 1.0 /
        (SELECT avg_monthly_sales_usd FROM yearly_avg WHERE year = 2019) AS growth_ratio
), projected_2021 AS (                       -- project every 2020 month into 2021
    SELECT
        month,
        monthly_sales_usd * (SELECT growth_ratio FROM growth_cte) AS projected_sales_usd
    FROM monthly_totals
    WHERE year = 2020
), ordered AS (                              -- rank projected months for median
    SELECT
        projected_sales_usd,
        ROW_NUMBER() OVER (ORDER BY projected_sales_usd) AS rn,
        COUNT(*)  OVER ()                                AS cnt
    FROM projected_2021
)
SELECT
    AVG(projected_sales_usd) AS median_projected_monthly_sales_usd_2021
FROM ordered
WHERE rn IN (
    CAST((cnt+1)/2 AS INTEGER),               -- middle row(s) for median
    CAST((cnt+2)/2 AS INTEGER)
);