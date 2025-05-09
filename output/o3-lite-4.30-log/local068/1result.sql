WITH month_totals AS (
    SELECT 
        substr("insert_date",1,4)            AS "year",
        strftime('%m',"insert_date")         AS "month_num",
        COUNT(*)                             AS "monthly_total"
    FROM "cities"
    WHERE strftime('%m',"insert_date") IN ('04','05','06')
      AND substr("insert_date",1,4) BETWEEN '2021' AND '2023'
    GROUP BY "year","month_num"
),
running_totals AS (
    SELECT
        "year",
        "month_num",
        "monthly_total",
        SUM("monthly_total") OVER (PARTITION BY "month_num"
                                   ORDER BY "year")  AS "cumulative_running_total"
    FROM month_totals
),
growth_calc AS (
    SELECT
        "year",
        "month_num",
        "monthly_total",
        "cumulative_running_total",
        LAG("monthly_total")            OVER (PARTITION BY "month_num" ORDER BY "year") AS "prev_month_total",
        LAG("cumulative_running_total") OVER (PARTITION BY "month_num" ORDER BY "year") AS "prev_run_total"
    FROM running_totals
)
SELECT
    "year",
    CASE "month_num"
         WHEN '04' THEN 'April'
         WHEN '05' THEN 'May'
         WHEN '06' THEN 'June'
    END                                           AS "month",
    "monthly_total",
    "cumulative_running_total",
    printf('%.4f', 100.0 * ("monthly_total" - "prev_month_total") / NULLIF("prev_month_total",0))  AS "monthly_total_yoy_growth_pct",
    printf('%.4f', 100.0 * ("cumulative_running_total" - "prev_run_total") / NULLIF("prev_run_total",0)) AS "running_total_yoy_growth_pct"
FROM growth_calc
WHERE "year" IN ('2022','2023')
ORDER BY "year","month_num";