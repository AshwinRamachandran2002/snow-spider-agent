WITH month_counts AS (
    -- 1.  Count how many cities were inserted in April-June for each year 2021-2023
    SELECT
        substr("insert_date",1,4)                             AS year,
        substr("insert_date",6,2)                             AS month_num,
        CASE substr("insert_date",6,2)
             WHEN '04' THEN 'April'
             WHEN '05' THEN 'May'
             WHEN '06' THEN 'June'
        END                                                   AS month_name,
        COUNT(*)                                              AS monthly_total
    FROM   "cities"
    WHERE  substr("insert_date",6,2) IN ('04','05','06')
      AND  substr("insert_date",1,4) BETWEEN '2021' AND '2023'
    GROUP  BY year, month_num
),
running_totals AS (
    -- 2.  Create the running (cumulative) total for each month across the years
    SELECT
        year,
        month_num,
        month_name,
        monthly_total,
        SUM(monthly_total) OVER (PARTITION BY month_num
                                 ORDER BY year)                AS running_total
    FROM   month_counts
),
yoy AS (
    -- 3.  Add year-over-year growth for both the monthly total and the running total
    SELECT
        year,
        month_num,
        month_name,
        monthly_total,
        running_total,
        ROUND(
              100.0 * (monthly_total - LAG(monthly_total) OVER (PARTITION BY month_num ORDER BY year))
              / LAG(monthly_total)         OVER (PARTITION BY month_num ORDER BY year)
              , 2)                                         AS yoy_growth_pct_monthly,
        ROUND(
              100.0 * (running_total - LAG(running_total) OVER (PARTITION BY month_num ORDER BY year))
              / LAG(running_total)         OVER (PARTITION BY month_num ORDER BY year)
              , 2)                                         AS yoy_growth_pct_running
    FROM   running_totals
)
-- 4.  Show only 2022-2023 as required
SELECT
    year,
    month_name,
    monthly_total               AS "cities_added_in_month",
    running_total               AS "running_total_for_month",
    yoy_growth_pct_monthly      AS "yoy_growth_pct_monthly",
    yoy_growth_pct_running      AS "yoy_growth_pct_running"
FROM   yoy
WHERE  year IN ('2022','2023')
ORDER  BY month_num, year;