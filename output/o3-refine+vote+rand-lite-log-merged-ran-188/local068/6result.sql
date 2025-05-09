WITH city_months AS (
    /* keep only April‑June rows for 2021‑2023 */
    SELECT 
        CAST(strftime('%Y', insert_date) AS INTEGER)  AS year,
        strftime('%m', insert_date)                   AS month_num,
        CASE strftime('%m', insert_date)
             WHEN '04' THEN 'April'
             WHEN '05' THEN 'May'
             WHEN '06' THEN 'June'
        END                                          AS month_name
    FROM cities
    WHERE year BETWEEN 2021 AND 2023
      AND month_num IN ('04','05','06')
),
monthly_counts AS (
    /* number of new cities each month of each year */
    SELECT
        year,
        month_num,
        month_name,
        COUNT(*) AS monthly_total
    FROM city_months
    GROUP BY year, month_num, month_name
),
running_totals AS (
    /* cumulative total for that month across the years */
    SELECT
        year,
        month_num,
        month_name,
        monthly_total,
        SUM(monthly_total) OVER (PARTITION BY month_num ORDER BY year) 
            AS running_total
    FROM monthly_counts
),
final_calc AS (
    /* add previous‑year values to compute YoY growth */
    SELECT
        year,
        month_num,
        month_name,
        monthly_total,
        running_total,
        LAG(monthly_total)  OVER (PARTITION BY month_num ORDER BY year) 
            AS prev_month_total,
        LAG(running_total)  OVER (PARTITION BY month_num ORDER BY year) 
            AS prev_running_total
    FROM running_totals
)
SELECT
    year,
    month_name                  AS month,
    monthly_total,
    running_total,
    ROUND(
        CASE 
            WHEN prev_month_total IS NULL OR prev_month_total = 0 
                 THEN NULL
            ELSE (monthly_total - prev_month_total)*100.0/prev_month_total
        END, 4)                 AS yoy_growth_monthly_percent,
    ROUND(
        CASE 
            WHEN prev_running_total IS NULL OR prev_running_total = 0 
                 THEN NULL
            ELSE (running_total - prev_running_total)*100.0/prev_running_total
        END, 4)                 AS yoy_growth_running_percent
FROM final_calc
WHERE year IN (2022, 2023)           -- exclude baseline 2021
ORDER BY year, month_num;