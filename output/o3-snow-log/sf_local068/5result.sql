WITH cities_parsed AS (   -- convert text to date
    SELECT 
        TO_DATE("insert_date") AS insert_dt
    FROM CITY_LEGISLATION.CITY_LEGISLATION.CITIES
    WHERE "insert_date" IS NOT NULL
), 
monthly_counts AS (       -- count new cities by year-month
    SELECT
        EXTRACT(YEAR  FROM insert_dt)  AS yr,
        EXTRACT(MONTH FROM insert_dt)  AS mon,
        TO_CHAR(insert_dt, 'Month')    AS month_name,
        COUNT(*)                       AS monthly_total
    FROM cities_parsed
    WHERE EXTRACT(YEAR  FROM insert_dt) BETWEEN 2021 AND 2023
      AND   EXTRACT(MONTH FROM insert_dt) IN (4,5,6)            -- April, May, June
    GROUP BY yr, mon, month_name
),
running_totals AS (       -- running total for each month across years
    SELECT
        yr,
        mon,
        month_name,
        monthly_total,
        SUM(monthly_total) OVER (PARTITION BY mon 
                                 ORDER BY yr 
                                 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) 
          AS running_total
    FROM monthly_counts
),
with_growth AS (          -- compute YoY growth for monthly & running totals
    SELECT
        yr      AS year,
        mon,
        INITCAP(TRIM(month_name))           AS month,
        monthly_total,
        running_total,
        LAG(monthly_total)  OVER (PARTITION BY mon ORDER BY yr) AS prev_monthly_total,
        LAG(running_total)  OVER (PARTITION BY mon ORDER BY yr) AS prev_running_total
    FROM running_totals
)
SELECT
    year,
    month,
    monthly_total            AS total_new_cities_in_month,
    running_total            AS cumulative_running_total,
    CASE 
        WHEN prev_monthly_total IS NULL OR prev_monthly_total = 0 THEN NULL
        ELSE ROUND((monthly_total - prev_monthly_total) * 100.0 / prev_monthly_total, 4)
    END                      AS yoy_monthly_growth_pct,
    CASE 
        WHEN prev_running_total IS NULL OR prev_running_total = 0 THEN NULL
        ELSE ROUND((running_total - prev_running_total) * 100.0 / prev_running_total, 4)
    END                      AS yoy_running_growth_pct
FROM with_growth
WHERE year IN (2022, 2023)       -- exclude baseline year 2021
ORDER BY year, mon;