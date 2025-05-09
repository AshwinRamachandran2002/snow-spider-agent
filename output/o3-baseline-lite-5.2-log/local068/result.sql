WITH month_counts AS (
    -- how many cities were inserted in Apr‑Jun for every year 2021‑2023
    SELECT
        CAST(strftime('%Y', "insert_date") AS INTEGER)      AS year,
        CASE strftime('%m', "insert_date")
               WHEN '04' THEN 'April'
               WHEN '05' THEN 'May'
               WHEN '06' THEN 'June'
        END                                               AS month_name,
        COUNT(*)                                          AS monthly_total
    FROM "cities"
    WHERE strftime('%m', "insert_date") IN ('04','05','06')
      AND CAST(strftime('%Y', "insert_date") AS INTEGER) BETWEEN 2021 AND 2023
    GROUP BY year, month_name
),
-- make sure we have a row for every month/year even when zero cities were added
month_year_grid AS (
    SELECT y.year, m.month_name
    FROM (SELECT 2021 AS year UNION ALL SELECT 2022 UNION ALL SELECT 2023) y
    CROSS JOIN (SELECT 'April' AS month_name
                UNION ALL SELECT 'May'
                UNION ALL SELECT 'June') m
),
month_counts_full AS (
    SELECT
        g.year,
        g.month_name,
        COALESCE(c.monthly_total,0) AS monthly_total
    FROM month_year_grid g
    LEFT JOIN month_counts c
           ON c.year = g.year
          AND c.month_name = g.month_name
),
running_totals AS (
    -- running (cumulative) total for each month up to and incl. current year
    SELECT
        f.year,
        f.month_name,
        f.monthly_total,
        (SELECT SUM(f2.monthly_total)
         FROM month_counts_full f2
         WHERE f2.month_name = f.month_name
           AND f2.year <= f.year)        AS running_total
    FROM month_counts_full f
),
yoy_calc AS (
    SELECT
        r.year,
        r.month_name,
        r.monthly_total,
        r.running_total,
        -- previous‑year values (per month)
        LAG(r.monthly_total) OVER (PARTITION BY r.month_name ORDER BY r.year)  AS prev_monthly_total,
        LAG(r.running_total) OVER (PARTITION BY r.month_name ORDER BY r.year)  AS prev_running_total
    FROM running_totals r
),
final AS (
    SELECT
        year,
        month_name                                       AS month,
        monthly_total,
        running_total,
        -- YoY % for the monthly total
        CASE 
            WHEN prev_monthly_total IS NULL OR prev_monthly_total = 0 THEN NULL
            ELSE ROUND(
                (monthly_total - prev_monthly_total) * 100.0 / prev_monthly_total,
                4)
        END                                              AS monthly_yoy_pct,
        -- YoY % for the running cumulative total
        CASE
            WHEN prev_running_total IS NULL OR prev_running_total = 0 THEN NULL
            ELSE ROUND(
                (running_total - prev_running_total) * 100.0 / prev_running_total,
                4)
        END                                              AS running_yoy_pct
    FROM yoy_calc
    WHERE year IN (2022, 2023)   -- exclude baseline year 2021
)
SELECT
    year,
    month,
    monthly_total,
    running_total,
    monthly_yoy_pct  AS monthly_yoy_growth_percentage,
    running_yoy_pct  AS running_yoy_growth_percentage
FROM final
ORDER BY
    year,
    CASE month
        WHEN 'April' THEN 4
        WHEN 'May'   THEN 5
        WHEN 'June'  THEN 6
    END;