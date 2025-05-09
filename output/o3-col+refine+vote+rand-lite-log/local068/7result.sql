WITH month_counts AS (
    /* 1.  Count new cities added in April-June for each year 2021-2023 */
    SELECT
        strftime('%Y', "insert_date") AS year,
        strftime('%m', "insert_date") AS month,
        COUNT(*)                     AS month_total
    FROM "cities"
    WHERE strftime('%m', "insert_date") IN ('04','05','06')
      AND strftime('%Y', "insert_date") BETWEEN '2021' AND '2023'
    GROUP BY year, month
),
running_totals AS (
    /* 2.  Cumulative running total for each month across the years */
    SELECT
        year,
        month,
        month_total,
        SUM(month_total) OVER (PARTITION BY month ORDER BY year) AS running_total
    FROM month_counts
),
yoy_calc AS (
    /* 3.  Year-over-year growth for the monthly total and running total */
    SELECT
        year,
        month,
        month_total,
        running_total,
        ROUND(
            (month_total - LAG(month_total) OVER (PARTITION BY month ORDER BY year))
            * 100.0 / LAG(month_total) OVER (PARTITION BY month ORDER BY year),
            4
        ) AS yoy_month_pct,
        ROUND(
            (running_total - LAG(running_total) OVER (PARTITION BY month ORDER BY year))
            * 100.0 / LAG(running_total) OVER (PARTITION BY month ORDER BY year),
            4
        ) AS yoy_running_pct
    FROM running_totals
)
SELECT
    year,
    CASE month
        WHEN '04' THEN 'April'
        WHEN '05' THEN 'May'
        WHEN '06' THEN 'June'
    END               AS month_name,
    month_total,
    running_total,
    yoy_month_pct,
    yoy_running_pct
FROM yoy_calc
WHERE year IN ('2022', '2023')         -- exclude baseline 2021
ORDER BY year, month;                  -- April, May, June sequence