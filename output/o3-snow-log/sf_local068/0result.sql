/* 1)  Gather rows for April-June, 2021-2023
   2)  Count cities per (year, month)
   3)  Derive cumulative running total per month across years
   4)  Compute YoY % growth for both the monthly total and the running total
   5)  Return only 2022-2023 results
*/
WITH date_prep AS (     -- step-1
    SELECT
        TO_DATE("insert_date")                                                   AS insert_dt,
        EXTRACT(year  FROM TO_DATE("insert_date"))                               AS yr,
        EXTRACT(month FROM TO_DATE("insert_date"))                               AS mn,
        INITCAP(TRIM(TO_CHAR(TO_DATE("insert_date"), 'Month')))                  AS month_name
    FROM CITY_LEGISLATION.CITY_LEGISLATION.CITIES
    WHERE EXTRACT(year  FROM TO_DATE("insert_date")) BETWEEN 2021 AND 2023
      AND   EXTRACT(month FROM TO_DATE("insert_date")) IN (4,5,6)                -- April, May, June
),
monthly_totals AS (      -- step-2
    SELECT
        yr  AS year,
        mn  AS month_number,
        month_name,
        COUNT(*) AS monthly_total
    FROM date_prep
    GROUP BY yr, mn, month_name
),
with_running AS (        -- step-3
    SELECT
        mt.*,
        SUM(monthly_total) OVER (PARTITION BY month_number
                                 ORDER BY year
                                 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
    FROM monthly_totals mt
),
final_calc AS (          -- step-4
    SELECT
        year,
        month_number,
        month_name,
        monthly_total,
        running_total,
        /* YoY % for the monthly total */
        CASE
            WHEN COALESCE(LAG(monthly_total) OVER (PARTITION BY month_number ORDER BY year),0)=0
            THEN NULL
            ELSE ROUND(
                 (monthly_total
                  - LAG(monthly_total) OVER (PARTITION BY month_number ORDER BY year))
                 / LAG(monthly_total) OVER (PARTITION BY month_number ORDER BY year) * 100, 4)
        END AS monthly_total_yoy_pct,
        /* YoY % for the running total */
        CASE
            WHEN COALESCE(LAG(running_total) OVER (PARTITION BY month_number ORDER BY year),0)=0
            THEN NULL
            ELSE ROUND(
                 (running_total
                  - LAG(running_total) OVER (PARTITION BY month_number ORDER BY year))
                 / LAG(running_total) OVER (PARTITION BY month_number ORDER BY year) * 100, 4)
        END AS running_total_yoy_pct
    FROM with_running
)
-- step-5 : deliver only 2022 & 2023
SELECT
    year,
    month_name,
    monthly_total,
    running_total,
    monthly_total_yoy_pct,
    running_total_yoy_pct
FROM final_calc
WHERE year IN (2022, 2023)
ORDER BY year, month_number;