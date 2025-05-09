SELECT
    year,
    CASE month_num
         WHEN '04' THEN 'April'
         WHEN '05' THEN 'May'
         WHEN '06' THEN 'June'
    END                                                    AS month,
    total_added                                            AS monthly_total,
    month_running_total                                    AS cumulative_running_total,
    ROUND(
        100.0 * (total_added - prev_year_total)
        / NULLIF(prev_year_total, 0), 4
    )                                                      AS monthly_total_yoy_growth_pct,
    ROUND(
        100.0 * (month_running_total - prev_running_total)
        / NULLIF(prev_running_total, 0), 4
    )                                                      AS running_total_yoy_growth_pct
FROM (
    SELECT
        year,
        month_num,
        total_added,
        month_running_total,
        LAG(total_added) OVER (PARTITION BY month_num ORDER BY year)         AS prev_year_total,
        LAG(month_running_total) OVER (PARTITION BY month_num ORDER BY year) AS prev_running_total
    FROM (
        SELECT
            strftime('%Y', insert_date)                             AS year,
            strftime('%m', insert_date)                             AS month_num,
            COUNT(*)                                                AS total_added,
            SUM(COUNT(*)) OVER (
                PARTITION BY strftime('%m', insert_date)
                ORDER BY strftime('%Y', insert_date)
            )                                                       AS month_running_total
        FROM cities
        WHERE strftime('%m', insert_date) IN ('04', '05', '06')
          AND strftime('%Y', insert_date) BETWEEN '2021' AND '2023'
        GROUP BY year, month_num
    )
)
WHERE year IN ('2022', '2023')
ORDER BY
    year,
    CASE month_num WHEN '04' THEN 4 WHEN '05' THEN 5 WHEN '06' THEN 6 END;