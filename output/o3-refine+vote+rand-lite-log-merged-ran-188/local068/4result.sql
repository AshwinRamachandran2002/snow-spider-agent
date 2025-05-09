WITH monthly_counts AS (
    /* 1.  Count how many cities were inserted in April‑June of each year 2021‑2023 */
    SELECT 
        CAST(strftime('%Y', "insert_date") AS INTEGER)               AS year,
        strftime('%m', "insert_date")                                AS month_num,
        CASE strftime('%m', "insert_date")
            WHEN '04' THEN 'April'
            WHEN '05' THEN 'May'
            WHEN '06' THEN 'June'
        END                                                         AS month_name,
        COUNT(*)                                                     AS monthly_total
    FROM  "cities"
    WHERE strftime('%m', "insert_date") IN ('04','05','06')
      AND CAST(strftime('%Y', "insert_date") AS INTEGER) BETWEEN 2021 AND 2023
    GROUP BY year, month_num
),
running_totals AS (
    /* 2.  Running‑total of cities for each month across the years */
    SELECT
        year,
        month_num,
        month_name,
        monthly_total,
        SUM(monthly_total) OVER (PARTITION BY month_num ORDER BY year)  AS running_total
    FROM monthly_counts
),
growth_calc AS (
    /* 3.  Pull previous‑year values to compute YoY growth */
    SELECT
        year,
        month_num,
        month_name,
        monthly_total,
        running_total,
        LAG(monthly_total)  OVER (PARTITION BY month_num ORDER BY year) AS prev_monthly_total,
        LAG(running_total)  OVER (PARTITION BY month_num ORDER BY year) AS prev_running_total
    FROM running_totals
)
SELECT
    year,
    month_name                                    AS month,
    monthly_total,
    running_total,
    ROUND(
        CASE 
            WHEN prev_monthly_total IS NULL OR prev_monthly_total = 0 
            THEN NULL
            ELSE ( (monthly_total - prev_monthly_total) * 100.0 / prev_monthly_total )
        END, 4)                                   AS monthly_growth_pct,
    ROUND(
        CASE 
            WHEN prev_running_total IS NULL OR prev_running_total = 0 
            THEN NULL
            ELSE ( (running_total - prev_running_total) * 100.0 / prev_running_total )
        END, 4)                                   AS running_total_growth_pct
FROM   growth_calc
WHERE  year IN (2022, 2023)                -- exclude 2021; it’s only the baseline
ORDER BY year, month_num;