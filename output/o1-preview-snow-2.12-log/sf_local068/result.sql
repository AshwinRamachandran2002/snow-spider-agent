WITH monthly_totals AS (
  SELECT 
    YEAR(TO_DATE("insert_date",'YYYY-MM-DD')) AS "year",
    MONTH(TO_DATE("insert_date",'YYYY-MM-DD')) AS "month",
    COUNT(*) AS "total_cities_added"
  FROM "CITY_LEGISLATION"."CITY_LEGISLATION"."CITIES"
  WHERE MONTH(TO_DATE("insert_date",'YYYY-MM-DD')) IN (4,5,6)
    AND YEAR(TO_DATE("insert_date",'YYYY-MM-DD')) BETWEEN 2021 AND 2023
  GROUP BY 1,2
),
cumulative_totals AS (
  SELECT
    "year",
    "month",
    "total_cities_added",
    SUM("total_cities_added") OVER (PARTITION BY "year" ORDER BY "month") AS "running_cumulative_total"
  FROM monthly_totals
),
previous_year_data AS (
  SELECT
    "year" + 1 AS "year",
    "month",
    "total_cities_added" AS "prev_total_cities_added",
    "running_cumulative_total" AS "prev_running_cumulative_total"
  FROM cumulative_totals
  WHERE "year" BETWEEN 2021 AND 2022
),
final_data AS (
  SELECT 
    curr."year",
    curr."month",
    curr."total_cities_added",
    curr."running_cumulative_total",
    ROUND(
      (curr."total_cities_added" - prev."prev_total_cities_added") 
      / NULLIF(prev."prev_total_cities_added", 0) * 100, 4
    ) AS "YoY_monthly_growth",
    ROUND(
      (curr."running_cumulative_total" - prev."prev_running_cumulative_total") 
      / NULLIF(prev."prev_running_cumulative_total", 0) * 100, 4
    ) AS "YoY_running_total_growth"
  FROM cumulative_totals curr
  LEFT JOIN previous_year_data prev 
    ON curr."year" = prev."year" AND curr."month" = prev."month"
  WHERE curr."year" > 2021
)
SELECT
  CAST("year" AS VARCHAR) AS "Year",
  CASE "month"
    WHEN 4 THEN 'April'
    WHEN 5 THEN 'May'
    WHEN 6 THEN 'June'
  END AS "Month",
  "total_cities_added" AS "Total_cities_added",
  "running_cumulative_total" AS "Running_cumulative_total",
  "YoY_monthly_growth",
  "YoY_running_total_growth"
FROM final_data
ORDER BY "year", "month";