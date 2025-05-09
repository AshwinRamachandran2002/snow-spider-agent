WITH date_prep AS (
    /* pick only April-June rows for 2021-2023 and convert the text date */
    SELECT
        EXTRACT(YEAR  FROM TO_DATE("insert_date",'YYYY-MM-DD'))  AS yr,
        EXTRACT(MONTH FROM TO_DATE("insert_date",'YYYY-MM-DD'))  AS mon
    FROM CITY_LEGISLATION.CITY_LEGISLATION.CITIES
    WHERE EXTRACT(MONTH FROM TO_DATE("insert_date",'YYYY-MM-DD')) IN (4,5,6)
      AND EXTRACT(YEAR  FROM TO_DATE("insert_date",'YYYY-MM-DD')) BETWEEN 2021 AND 2023
),
month_counts AS (
    /* cities added in each month of each year */
    SELECT
        yr                                                  AS year,
        mon                                                 AS month_num,
        CASE mon WHEN 4 THEN 'April'
                 WHEN 5 THEN 'May'
                 WHEN 6 THEN 'June' END                    AS month,
        COUNT(*)                                            AS month_total
    FROM date_prep
    GROUP BY yr, mon
),
running_totals AS (
    /* cumulative running total for the same month across years */
    SELECT
        mc.*,
        SUM(mc.month_total) OVER (PARTITION BY mc.month_num
                                  ORDER BY mc.year
                                  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
    FROM month_counts mc
),
growth_calc AS (
    /* bring in previous-year values to compute YoY growth */
    SELECT
        rt.*,
        LAG(rt.month_total)   OVER (PARTITION BY rt.month_num ORDER BY rt.year) AS prev_month_total,
        LAG(rt.running_total) OVER (PARTITION BY rt.month_num ORDER BY rt.year) AS prev_running_total
    FROM running_totals rt
)
SELECT
    year,
    month,
    month_total       AS total_cities_added,
    running_total     AS cumulative_running_total,
    CASE
        WHEN prev_month_total   IS NULL OR prev_month_total   = 0 THEN NULL
        ELSE ROUND((month_total   - prev_month_total)   / prev_month_total   * 100, 4)
    END               AS yoy_monthly_growth_percent,
    CASE
        WHEN prev_running_total IS NULL OR prev_running_total = 0 THEN NULL
        ELSE ROUND((running_total - prev_running_total) / prev_running_total * 100, 4)
    END               AS yoy_running_growth_percent
FROM growth_calc
WHERE year IN (2022, 2023)          -- exclude baseline year 2021 from display
ORDER BY
    year,
    CASE month WHEN 'April' THEN 1 WHEN 'May' THEN 2 WHEN 'June' THEN 3 END;