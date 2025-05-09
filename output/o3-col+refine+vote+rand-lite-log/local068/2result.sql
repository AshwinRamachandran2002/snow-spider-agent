WITH month_counts AS (
    -- 1.  Monthly totals for April, May and June (2021-2023)
    SELECT
        strftime('%Y', "insert_date")                                     AS "year",
        strftime('%m', "insert_date")                                     AS "mon_num",
        CASE strftime('%m', "insert_date")
             WHEN '04' THEN 'April'
             WHEN '05' THEN 'May'
             WHEN '06' THEN 'June'
        END                                                              AS "month_name",
        COUNT(*)                                                         AS "month_total"
    FROM "cities"
    WHERE strftime('%m', "insert_date") IN ('04', '05', '06')
      AND strftime('%Y', "insert_date") BETWEEN '2021' AND '2023'
    GROUP BY "year", "mon_num"
),
running_totals AS (
    -- 2.  Cumulative running total for each month across years
    SELECT
        mc.*,
        SUM("month_total") OVER (PARTITION BY "mon_num"
                                 ORDER BY "year")                        AS "running_total"
    FROM month_counts mc
),
with_lags AS (
    -- 3.  Bring in previous-year values for YoY calculations
    SELECT
        rt.*,
        LAG("month_total")   OVER (PARTITION BY "mon_num"
                                   ORDER BY "year")                      AS "prev_month_total",
        LAG("running_total") OVER (PARTITION BY "mon_num"
                                   ORDER BY "year")                      AS "prev_running_total"
    FROM running_totals rt
)
-- 4.  Final result – only 2022 & 2023
SELECT
    "year",
    "month_name",
    "month_total",
    "running_total",
    ROUND( (("month_total"  - "prev_month_total")  * 100.0) / "prev_month_total", 4)
        AS "yoy_month_pct",
    ROUND( (("running_total" - "prev_running_total") * 100.0) / "prev_running_total", 4)
        AS "yoy_running_pct"
FROM with_lags
WHERE "year" IN ('2022', '2023')
ORDER BY
    "year",
    CASE "month_name"
         WHEN 'April' THEN 1
         WHEN 'May'   THEN 2
         WHEN 'June'  THEN 3
    END;