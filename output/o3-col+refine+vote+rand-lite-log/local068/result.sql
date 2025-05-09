WITH monthly AS (
    -- 1.  Count new cities inserted in Apr-Jun for each year 2021-2023
    SELECT CAST(substr("insert_date",1,4) AS INT)                       AS year,
           CASE substr("insert_date",6,2)
                WHEN '04' THEN 'April'
                WHEN '05' THEN 'May'
                WHEN '06' THEN 'June'
           END                                                         AS month,
           COUNT(*)                                                    AS monthly_total
    FROM   "cities"
    WHERE  substr("insert_date",6,2) IN ('04','05','06')
      AND  substr("insert_date",1,4) IN ('2021','2022','2023')
    GROUP  BY year, month
),
running AS (
    -- 2.  Running (cumulative) total for each month across years
    SELECT  year,
            month,
            monthly_total,
            SUM(monthly_total) OVER (PARTITION BY month ORDER BY year) AS running_total
    FROM    monthly
),
growth AS (
    -- 3.  YoY growth for monthly and running totals
    SELECT  year,
            month,
            monthly_total,
            running_total,
            ROUND(
                (monthly_total - LAG(monthly_total) OVER (PARTITION BY month ORDER BY year))
                * 100.0 /
                LAG(monthly_total) OVER (PARTITION BY month ORDER BY year), 2
            )                                                         AS monthly_yoy_pct,
            ROUND(
                (running_total - LAG(running_total) OVER (PARTITION BY month ORDER BY year))
                * 100.0 /
                LAG(running_total) OVER (PARTITION BY month ORDER BY year), 2
            )                                                         AS running_yoy_pct
    FROM    running
)
-- 4.  Deliver only 2022-2023 rows, keeping 2021 only for baseline calcs
SELECT  year,
        month,
        monthly_total                       AS total_added_in_month,
        running_total                       AS cumulative_running_total,
        monthly_yoy_pct                     AS monthly_yoy_growth_pct,
        running_yoy_pct                     AS running_yoy_growth_pct
FROM    growth
WHERE   year IN (2022, 2023)
ORDER   BY
        CASE month
             WHEN 'April' THEN 4
             WHEN 'May'   THEN 5
             WHEN 'June'  THEN 6
        END,
        year;