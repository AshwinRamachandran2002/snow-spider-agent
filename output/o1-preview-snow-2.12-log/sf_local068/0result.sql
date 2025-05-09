WITH monthly_totals AS (
    SELECT
        EXTRACT(YEAR FROM TO_DATE("insert_date", 'YYYY-MM-DD')) AS "Year",
        EXTRACT(MONTH FROM TO_DATE("insert_date", 'YYYY-MM-DD')) AS "Month_number",
        CASE
            WHEN EXTRACT(MONTH FROM TO_DATE("insert_date", 'YYYY-MM-DD')) = 4 THEN 'April'
            WHEN EXTRACT(MONTH FROM TO_DATE("insert_date", 'YYYY-MM-DD')) = 5 THEN 'May'
            WHEN EXTRACT(MONTH FROM TO_DATE("insert_date", 'YYYY-MM-DD')) = 6 THEN 'June'
        END AS "Month",
        COUNT(*) AS "Total_cities_added"
    FROM "CITY_LEGISLATION"."CITY_LEGISLATION"."CITIES"
    WHERE
        EXTRACT(MONTH FROM TO_DATE("insert_date", 'YYYY-MM-DD')) IN (4, 5, 6)
        AND EXTRACT(YEAR FROM TO_DATE("insert_date", 'YYYY-MM-DD')) BETWEEN 2021 AND 2023
    GROUP BY
        EXTRACT(YEAR FROM TO_DATE("insert_date", 'YYYY-MM-DD')),
        EXTRACT(MONTH FROM TO_DATE("insert_date", 'YYYY-MM-DD'))
),
monthly_totals_with_cumulative AS (
    SELECT
        "Year",
        "Month_number",
        "Month",
        "Total_cities_added",
        SUM("Total_cities_added") OVER (PARTITION BY "Year" ORDER BY "Month_number") AS "Running_cumulative_total"
    FROM monthly_totals
),
final_data AS (
    SELECT
        mt."Year",
        mt."Month_number",
        mt."Month",
        mt."Total_cities_added",
        mt."Running_cumulative_total",
        pmt."Total_cities_added" AS "Prior_year_total_cities_added",
        pmt."Running_cumulative_total" AS "Prior_year_running_cumulative_total"
    FROM monthly_totals_with_cumulative mt
    LEFT JOIN monthly_totals_with_cumulative pmt
        ON mt."Year" = pmt."Year" + 1
        AND mt."Month_number" = pmt."Month_number"
)
SELECT
    "Year",
    "Month",
    "Total_cities_added",
    "Running_cumulative_total",
    ROUND(
        CASE
            WHEN "Prior_year_total_cities_added" IS NOT NULL AND "Prior_year_total_cities_added" <> 0 THEN
                (("Total_cities_added" - "Prior_year_total_cities_added") / "Prior_year_total_cities_added") * 100
            ELSE NULL
        END, 4) AS "YoY_monthly_growth",
    ROUND(
        CASE
            WHEN "Prior_year_running_cumulative_total" IS NOT NULL AND "Prior_year_running_cumulative_total" <> 0 THEN
                (("Running_cumulative_total" - "Prior_year_running_cumulative_total") / "Prior_year_running_cumulative_total") * 100
            ELSE NULL
        END, 4) AS "YoY_running_total_growth"
FROM final_data
WHERE "Year" IN (2022, 2023)
ORDER BY "Year", "Month_number";