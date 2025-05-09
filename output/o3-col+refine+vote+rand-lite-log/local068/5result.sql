WITH month_counts AS (
    -- 1.  Count how many new cities were inserted in April, May, and June for each year 2021-2023
    SELECT
        SUBSTR("insert_date", 1, 4)                  AS "year",
        SUBSTR("insert_date", 6, 2)                  AS "month",
        COUNT(*)                                     AS "month_total"
    FROM "cities"
    WHERE SUBSTR("insert_date", 1, 4) BETWEEN '2021' AND '2023'
      AND SUBSTR("insert_date", 6, 2) IN ('04','05','06')
    GROUP BY "year", "month"
),
running_totals AS (
    -- 2.  Cumulative running total for each month across years
    SELECT
        mc.*,
        SUM(mc."month_total") OVER (PARTITION BY mc."month"
                                    ORDER BY mc."year")  AS "running_total"
    FROM month_counts mc
),
yoy_growth AS (
    -- 3.  Year-over-year growth for month totals and running totals
    SELECT
        rt.*,
        ROUND(
            (rt."month_total"
             - LAG(rt."month_total") OVER (PARTITION BY rt."month" ORDER BY rt."year"))
            * 100.0
            / NULLIF(LAG(rt."month_total") OVER (PARTITION BY rt."month" ORDER BY rt."year"), 0),
            2
        ) AS "month_yoy_growth_pct",
        ROUND(
            (rt."running_total"
             - LAG(rt."running_total") OVER (PARTITION BY rt."month" ORDER BY rt."year"))
            * 100.0
            / NULLIF(LAG(rt."running_total") OVER (PARTITION BY rt."month" ORDER BY rt."year"), 0),
            2
        ) AS "running_yoy_growth_pct"
    FROM running_totals rt
)
-- 4.  Final report for 2022-2023 only (2021 serves as the baseline)
SELECT
    CASE "month"
        WHEN '04' THEN 'April'
        WHEN '05' THEN 'May'
        WHEN '06' THEN 'June'
    END                                   AS "month",
    "year",
    "month_total"                         AS "cities_added_in_month",
    "running_total"                       AS "cumulative_running_total",
    "month_yoy_growth_pct"                AS "MoM_total_YoY_growth_pct",
    "running_yoy_growth_pct"              AS "Running_total_YoY_growth_pct"
FROM yoy_growth
WHERE "year" IN ('2022','2023')
ORDER BY "year", "month";