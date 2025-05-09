WITH
-- months of interest
months AS (
    SELECT '04' AS month_num, 'April' AS month_name UNION ALL
    SELECT '05', 'May'  UNION ALL
    SELECT '06', 'June'
),
-- years we need (baseline + output years)
years AS (
    SELECT 2021 AS year UNION ALL
    SELECT 2022 UNION ALL
    SELECT 2023
),
-- every (year , month) combination
all_combos AS (
    SELECT y.year, m.month_num, m.month_name
    FROM years y
    CROSS JOIN months m
),
-- actual counts from the cities table
counts AS (
    SELECT
        CAST(strftime('%Y', "insert_date") AS INTEGER)      AS year,
        strftime('%m', "insert_date")                       AS month_num,
        COUNT(*)                                            AS monthly_total
    FROM "cities"
    WHERE strftime('%Y', "insert_date") BETWEEN '2021' AND '2023'
      AND strftime('%m', "insert_date") IN ('04','05','06')
    GROUP BY year, month_num
),
-- attach counts to the complete grid (fill missing with 0)
base AS (
    SELECT
        ac.year,
        ac.month_name,
        COALESCE(c.monthly_total, 0) AS monthly_total
    FROM all_combos ac
    LEFT JOIN counts c
           ON ac.year = c.year
          AND ac.month_num = c.month_num
),
-- cumulative running total per month across years
running AS (
    SELECT
        year,
        month_name,
        monthly_total,
        SUM(monthly_total) OVER (PARTITION BY month_name ORDER BY year
                                 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
    FROM base
),
-- year‑over‑year previous values
growth AS (
    SELECT
        year,
        month_name,
        monthly_total,
        running_total,
        LAG(monthly_total)  OVER (PARTITION BY month_name ORDER BY year) AS prev_monthly_total,
        LAG(running_total)  OVER (PARTITION BY month_name ORDER BY year) AS prev_running_total
    FROM running
)
SELECT
    year,
    month_name                                              AS month,
    monthly_total,
    running_total,
    CASE
        WHEN prev_monthly_total IS NULL OR prev_monthly_total = 0 THEN NULL
        ELSE ROUND( (monthly_total - prev_monthly_total)*100.0 / prev_monthly_total , 4)
    END                                                     AS monthly_yoy_growth_pct,
    CASE
        WHEN prev_running_total IS NULL OR prev_running_total = 0 THEN NULL
        ELSE ROUND( (running_total - prev_running_total)*100.0 / prev_running_total , 4)
    END                                                     AS running_total_yoy_growth_pct
FROM growth
WHERE year IN (2022, 2023)                       -- exclude baseline year 2021
ORDER BY year,
         CASE month WHEN 'April' THEN 4
                    WHEN 'May'   THEN 5
                    WHEN 'June'  THEN 6
         END;