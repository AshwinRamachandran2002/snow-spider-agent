WITH month_filter AS (   -- 1. keep April-June for 2021-2023
    SELECT  
        EXTRACT(YEAR  FROM TO_DATE("insert_date"))  AS "year",
        EXTRACT(MONTH FROM TO_DATE("insert_date"))  AS "month_num"
    FROM CITY_LEGISLATION.CITY_LEGISLATION.CITIES
    WHERE EXTRACT(YEAR  FROM TO_DATE("insert_date")) BETWEEN 2021 AND 2023
      AND EXTRACT(MONTH FROM TO_DATE("insert_date")) IN (4,5,6)
), 
month_counts AS (        -- 2. count cities added each (year, month)
    SELECT
        "year",
        "month_num",
        COUNT(*) AS "monthly_total"
    FROM month_filter
    GROUP BY "year","month_num"
),
running_step1 AS (       -- 3a. running total by month across years
    SELECT
        "year",
        "month_num",
        "monthly_total",
        SUM("monthly_total") OVER (PARTITION BY "month_num"
                                   ORDER BY "year"
                                   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) 
                                   AS "running_total"
    FROM month_counts
),
running_totals AS (      -- 3b. previous-year values for YoY calculations
    SELECT
        rs1.*,
        LAG("monthly_total") OVER (PARTITION BY "month_num" ORDER BY "year")  AS "prev_month_total",
        LAG("running_total") OVER (PARTITION BY "month_num" ORDER BY "year")  AS "prev_running_total"
    FROM running_step1 rs1
)
SELECT
    rt."year",
    CASE rt."month_num" WHEN 4 THEN 'April'
                        WHEN 5 THEN 'May'
                        WHEN 6 THEN 'June' END          AS "month",
    rt."monthly_total"                                AS "cities_added_this_month",
    rt."running_total"                                AS "cumulative_running_total_for_month",
    ROUND( (rt."monthly_total"  - rt."prev_month_total")   /
           NULLIF(rt."prev_month_total",0) * 100 , 4)  AS "yoy_growth_pct_monthly_total",
    ROUND( (rt."running_total" - rt."prev_running_total") /
           NULLIF(rt."prev_running_total",0) * 100 , 4)  AS "yoy_growth_pct_running_total"
FROM running_totals rt
WHERE rt."year" IN (2022, 2023)      -- 4. output only 2022 & 2023
ORDER BY rt."year", rt."month_num";