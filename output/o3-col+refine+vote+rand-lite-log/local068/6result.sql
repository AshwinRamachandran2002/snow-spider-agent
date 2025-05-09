WITH month_counts AS (
    SELECT 
        CAST(strftime('%Y', "insert_date") AS INTEGER) AS year,
        strftime('%m', "insert_date")                 AS month,
        COUNT(*)                                      AS month_total
    FROM "cities"
    WHERE strftime('%m', "insert_date") IN ('04','05','06')
          AND CAST(strftime('%Y', "insert_date") AS INTEGER) BETWEEN 2021 AND 2023
    GROUP BY year, month
),
running_totals AS (
    SELECT
        year,
        month,
        month_total,
        SUM(month_total) OVER (PARTITION BY month ORDER BY year) AS running_total
    FROM month_counts
),
lagged AS (
    SELECT
        year,
        month,
        month_total,
        running_total,
        LAG(month_total)  OVER (PARTITION BY month ORDER BY year) AS prev_month_total,
        LAG(running_total) OVER (PARTITION BY month ORDER BY year) AS prev_running_total
    FROM running_totals
)
SELECT
    year                                                                       AS "year",
    CASE month WHEN '04' THEN 'April'
               WHEN '05' THEN 'May'
               WHEN '06' THEN 'June' END                                        AS "month",
    month_total                                                                AS "cities_added_in_month",
    running_total                                                              AS "running_total_for_month",
    ROUND( (month_total  - prev_month_total)  * 100.0 / prev_month_total, 2 )  AS "yoy_month_growth_pct",
    ROUND( (running_total - prev_running_total) * 100.0 / prev_running_total, 2 ) AS "yoy_running_growth_pct"
FROM lagged
WHERE year IN (2022, 2023)
ORDER BY year, month;