WITH city_month_counts AS (          -- how many cities were inserted each month/year
    SELECT 
        CAST(strftime('%Y', insert_date) AS INTEGER)                AS year,
        strftime('%m', insert_date)                                 AS month_num,
        CASE strftime('%m', insert_date)
            WHEN '04' THEN 'April'
            WHEN '05' THEN 'May'
            WHEN '06' THEN 'June'
        END                                                        AS month_name,
        COUNT(*)                                                    AS month_count
    FROM cities
    WHERE strftime('%m', insert_date) IN ('04','05','06')
      AND CAST(strftime('%Y', insert_date) AS INTEGER) BETWEEN 2021 AND 2023
    GROUP BY year, month_num
),
months AS (                       -- ensure every month/year combination exists (fill with 0s)
    SELECT y.year,
           m.month_num,
           m.month_name
    FROM (SELECT 2021 AS year UNION ALL SELECT 2022 UNION ALL SELECT 2023) y
    CROSS JOIN (
        SELECT '04' AS month_num, 'April' AS month_name
        UNION ALL SELECT '05','May'
        UNION ALL SELECT '06','June'
    ) m
),
combined AS (                     -- counts with zeros filled in
    SELECT 
        months.year,
        months.month_name,
        COALESCE(c.month_count,0) AS month_count
    FROM months
    LEFT JOIN city_month_counts c
           ON months.year = c.year
          AND months.month_num = c.month_num
),
running AS (                      -- month‑specific cumulative running total
    SELECT
        year,
        month_name,
        month_count,
        SUM(month_count) OVER (PARTITION BY month_name
                               ORDER BY year
                               ROWS UNBOUNDED PRECEDING)          AS running_total
    FROM combined
),
with_prev AS (                    -- bring in previous‑year values
    SELECT
        year,
        month_name,
        month_count,
        running_total,
        LAG(month_count)  OVER (PARTITION BY month_name ORDER BY year) AS prev_month_count,
        LAG(running_total) OVER (PARTITION BY month_name ORDER BY year) AS prev_running_total
    FROM running
)
SELECT 
    year,
    month_name                                   AS month,
    month_count                                  AS cities_added_in_month,
    running_total                                AS cumulative_running_total_for_month,
    CASE                                          -- YoY % for the month
        WHEN prev_month_count IS NULL OR prev_month_count = 0 THEN NULL
        ELSE ROUND((month_count  - prev_month_count ) * 100.0 / prev_month_count, 4)
    END                                          AS month_yoy_growth_pct,
    CASE                                          -- YoY % for the running total
        WHEN prev_running_total IS NULL OR prev_running_total = 0 THEN NULL
        ELSE ROUND((running_total - prev_running_total) * 100.0 / prev_running_total, 4)
    END                                          AS running_total_yoy_growth_pct
FROM with_prev
WHERE year IN (2022, 2023)                       -- show only 2022‑2023
ORDER BY year,
         CASE month WHEN 'April' THEN 4
                    WHEN 'May'   THEN 5
                    WHEN 'June'  THEN 6 END;