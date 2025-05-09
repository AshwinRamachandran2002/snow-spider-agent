WITH city_months AS (
    /* keep only April-June rows for 2021-2023 */
    SELECT
        EXTRACT(year  FROM TO_DATE("insert_date"))                              AS year,
        EXTRACT(month FROM TO_DATE("insert_date"))                              AS month_number,
        INITCAP(TRIM(TO_CHAR(TO_DATE("insert_date"), 'Month')))                 AS month_name
    FROM CITY_LEGISLATION.CITY_LEGISLATION.CITIES
    WHERE EXTRACT(month FROM TO_DATE("insert_date")) IN (4,5,6)
      AND EXTRACT(year  FROM TO_DATE("insert_date")) BETWEEN 2021 AND 2023
), month_counts AS (
    /* monthly total new cities */
    SELECT
        year,
        month_number,
        month_name,
        COUNT(*)                                            AS monthly_total
    FROM city_months
    GROUP BY year, month_number, month_name
), running_totals AS (
    /* running cumulative total for the same month across years */
    SELECT
        year,
        month_number,
        month_name,
        monthly_total,
        SUM(monthly_total) OVER (PARTITION BY month_number
                                 ORDER BY year
                                 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)  AS running_total
    FROM month_counts
), with_growth AS (
    /* year-over-year growth for monthly and running totals */
    SELECT
        year,
        month_number,
        month_name,
        monthly_total,
        running_total,
        ROUND(
            (monthly_total
             - LAG(monthly_total) OVER (PARTITION BY month_number ORDER BY year))
            / NULLIF(LAG(monthly_total) OVER (PARTITION BY month_number ORDER BY year),0)
            * 100, 2)                                            AS yoy_monthly_growth_pct,
        ROUND(
            (running_total
             - LAG(running_total) OVER (PARTITION BY month_number ORDER BY year))
            / NULLIF(LAG(running_total) OVER (PARTITION BY month_number ORDER BY year),0)
            * 100, 2)                                            AS yoy_running_growth_pct
    FROM running_totals
)
SELECT
    year,
    month_name,
    monthly_total,
    running_total,
    yoy_monthly_growth_pct,
    yoy_running_growth_pct
FROM with_growth
WHERE year IN (2022, 2023)                 -- exclude 2021 from final output
ORDER BY year, month_number;