WITH filtered AS (
    /* keep only April, May and June for 2021‑2023 */
    SELECT
        CAST(strftime('%Y', insert_date) AS INTEGER)      AS year,
        CAST(strftime('%m', insert_date) AS INTEGER)      AS month_num,
        CASE strftime('%m', insert_date)
             WHEN '04' THEN 'April'
             WHEN '05' THEN 'May'
             WHEN '06' THEN 'June'
        END                                             AS month_name
    FROM cities
    WHERE strftime('%Y', insert_date) BETWEEN '2021' AND '2023'
      AND strftime('%m', insert_date) IN ('04','05','06')
),
monthly_totals AS (
    /* cities added each month/year */
    SELECT
        year,
        month_num,
        month_name,
        COUNT(*) AS monthly_total
    FROM filtered
    GROUP BY year, month_num
),
with_running AS (
    /* cumulative running total for the same month across years */
    SELECT
        mt.*,
        SUM(monthly_total) OVER (PARTITION BY month_num ORDER BY year) AS running_total
    FROM monthly_totals mt
),
final AS (
    /* year‑over‑year growth calculations */
    SELECT
        wr.*,
        LAG(monthly_total) OVER (PARTITION BY month_num ORDER BY year)  AS prev_monthly_total,
        LAG(running_total) OVER (PARTITION BY month_num ORDER BY year)  AS prev_running_total
    FROM with_running wr
)
SELECT
    year,
    month_name                    AS month,
    monthly_total,
    running_total,
    CASE
        WHEN prev_monthly_total IS NULL OR prev_monthly_total = 0
             THEN NULL
        ELSE ROUND((monthly_total - prev_monthly_total) * 100.0 / prev_monthly_total, 4)
    END                          AS yoy_monthly_growth_pct,
    CASE
        WHEN prev_running_total IS NULL OR prev_running_total = 0
             THEN NULL
        ELSE ROUND((running_total - prev_running_total) * 100.0 / prev_running_total, 4)
    END                          AS yoy_running_growth_pct
FROM final
WHERE year IN (2022, 2023)           -- exclude baseline year 2021 from output
ORDER BY year, month_num;