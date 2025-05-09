WITH monthly_totals AS (          -- 1. Cities added in Apr‑Jun 2021‑2023
    SELECT
        CAST(strftime('%Y', "insert_date") AS INTEGER)  AS year,
        CAST(strftime('%m', "insert_date") AS INTEGER)  AS month,
        COUNT(*)                                        AS monthly_total
    FROM   "cities"
    WHERE  CAST(strftime('%Y', "insert_date") AS INTEGER) BETWEEN 2021 AND 2023
      AND  CAST(strftime('%m', "insert_date") AS INTEGER) IN (4,5,6)
    GROUP  BY year, month
),
running_totals AS (               -- 2. Running total for each month
    SELECT
        year,
        month,
        monthly_total,
        SUM(monthly_total) OVER (PARTITION BY month ORDER BY year)
                                                AS running_total
    FROM   monthly_totals
),
lagged AS (                       -- 3. Bring previous‑year values
    SELECT
        year,
        month,
        monthly_total,
        running_total,
        LAG(monthly_total) OVER (PARTITION BY month ORDER BY year)
                                                AS prev_monthly_total,
        LAG(running_total) OVER (PARTITION BY month ORDER BY year)
                                                AS prev_running_total
    FROM   running_totals
),
final AS (                        -- 4. YoY growth; keep 2022‑2023
    SELECT
        year,
        month,
        CASE month WHEN 4 THEN 'April'
                   WHEN 5 THEN 'May'
                   WHEN 6 THEN 'June' END          AS month_name,
        monthly_total,
        running_total,
        CASE WHEN prev_monthly_total IS NULL OR prev_monthly_total = 0
             THEN NULL
             ELSE ROUND(
                    (monthly_total - prev_monthly_total) * 100.0
                    / prev_monthly_total, 4)
        END                                        AS monthly_yoy_growth_pct,
        CASE WHEN prev_running_total IS NULL OR prev_running_total = 0
             THEN NULL
             ELSE ROUND(
                    (running_total - prev_running_total) * 100.0
                    / prev_running_total, 4)
        END                                        AS running_yoy_growth_pct
    FROM   lagged
    WHERE  year IN (2022, 2023)
)
SELECT
    year,
    month_name                  AS month,
    monthly_total,
    running_total,
    monthly_yoy_growth_pct,
    running_yoy_growth_pct
FROM   final
ORDER  BY year, month;          -- month is numeric, guarantees Apr‑May‑Jun order