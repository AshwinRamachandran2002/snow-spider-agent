WITH
-- months we are interested in
months(month, month_name) AS (
  VALUES 
    ('04', 'April'),
    ('05', 'May'),
    ('06', 'June')
),
-- years to cover (baseline 2021 + years we will show)
years(year) AS (
  VALUES 
    ('2021'),
    ('2022'),
    ('2023')
),
-- every (year, month) combination
year_month AS (
  SELECT y.year, m.month, m.month_name
  FROM years y
  CROSS JOIN months m
),
-- actual city insert counts
monthly_counts AS (
  SELECT 
        strftime('%Y', insert_date) AS year,
        strftime('%m', insert_date) AS month,
        COUNT(*)                    AS monthly_total
  FROM cities
  WHERE strftime('%Y', insert_date) IN ('2021','2022','2023')
    AND strftime('%m', insert_date) IN ('04','05','06')
  GROUP BY year, month
),
-- ensure zero‑filled combinations
combined AS (
  SELECT 
        ym.year,
        ym.month,
        ym.month_name,
        COALESCE(mc.monthly_total, 0) AS monthly_total
  FROM year_month ym
  LEFT JOIN monthly_counts mc
    ON  ym.year  = mc.year
    AND ym.month = mc.month
),
-- running totals per month across years
running_step AS (
  SELECT
        year,
        month,
        month_name,
        monthly_total,
        SUM(monthly_total) OVER (PARTITION BY month ORDER BY year) AS running_total
  FROM combined
),
-- add previous‑year values to compute growth
running_with_prev AS (
  SELECT
        year,
        month,
        month_name,
        monthly_total,
        running_total,
        LAG(monthly_total)  OVER (PARTITION BY month ORDER BY year) AS prev_month_total,
        LAG(running_total)  OVER (PARTITION BY month ORDER BY year) AS prev_running_total
  FROM running_step
)
SELECT
      CAST(year AS INTEGER)                              AS year,
      month_name,
      monthly_total,
      running_total,
      CASE 
          WHEN prev_month_total   IS NULL OR prev_month_total   = 0 THEN NULL
          ELSE ROUND( (monthly_total - prev_month_total) * 100.0 / prev_month_total , 4)
      END                                                AS monthly_yoy_growth_pct,
      CASE 
          WHEN prev_running_total IS NULL OR prev_running_total = 0 THEN NULL
          ELSE ROUND( (running_total - prev_running_total) * 100.0 / prev_running_total , 4)
      END                                                AS running_yoy_growth_pct
FROM   running_with_prev
WHERE  year IN ('2022','2023')
ORDER BY 
      year,
      CASE month
           WHEN '04' THEN 1
           WHEN '05' THEN 2
           WHEN '06' THEN 3
      END;