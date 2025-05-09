WITH monthly AS (
    SELECT 
        substr("insert_date",1,4) AS year,
        substr("insert_date",6,2) AS month_num,
        COUNT(*)                  AS monthly_total
    FROM "cities"
    WHERE substr("insert_date",1,4) BETWEEN '2021' AND '2023'
      AND substr("insert_date",6,2) IN ('04','05','06')
    GROUP BY year, month_num
),
running AS (
    SELECT
        year,
        month_num,
        monthly_total,
        SUM(monthly_total) OVER (PARTITION BY month_num ORDER BY year) AS cumulative_running_total
    FROM monthly
),
final AS (
    SELECT
        year,
        month_num,   -- retained for ordering
        CASE month_num
            WHEN '04' THEN 'April'
            WHEN '05' THEN 'May'
            WHEN '06' THEN 'June'
        END                                           AS month,
        monthly_total,
        cumulative_running_total,
        ROUND(
              100.0 * (monthly_total - LAG(monthly_total) OVER (PARTITION BY month_num ORDER BY year))
              / LAG(monthly_total) OVER (PARTITION BY month_num ORDER BY year)
        ,4)                                           AS monthly_total_yoy_growth_pct,
        ROUND(
              100.0 * (cumulative_running_total - LAG(cumulative_running_total) OVER (PARTITION BY month_num ORDER BY year))
              / LAG(cumulative_running_total) OVER (PARTITION BY month_num ORDER BY year)
        ,4)                                           AS running_total_yoy_growth_pct
    FROM running
)
SELECT 
    year,
    month,
    monthly_total,
    cumulative_running_total,
    monthly_total_yoy_growth_pct,
    running_total_yoy_growth_pct
FROM final
WHERE year IN ('2022','2023')
ORDER BY month_num, year;