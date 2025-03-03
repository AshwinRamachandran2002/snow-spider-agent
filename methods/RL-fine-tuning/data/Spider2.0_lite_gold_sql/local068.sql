WITH monthly_totals AS (
    SELECT
        CAST(strftime('%Y', "insert_date") AS INTEGER) AS year,
        CAST(strftime('%m', "insert_date") AS INTEGER) AS month,
        COUNT(*) AS cities_added
    FROM "cities"
    WHERE
        CAST(strftime('%Y', "insert_date") AS INTEGER) BETWEEN 2021 AND 2023
        AND CAST(strftime('%m', "insert_date") AS INTEGER) IN (4, 5, 6)
    GROUP BY year, month
),
cumulative_totals AS (
    SELECT
        year,
        month,
        cities_added,
        SUM(cities_added) OVER (PARTITION BY year ORDER BY month) AS running_total
    FROM monthly_totals
),
prev_year_totals AS (
    SELECT
        year + 1 AS year,
        month,
        cities_added AS prev_cities_added,
        running_total AS prev_running_total
    FROM cumulative_totals
    WHERE year BETWEEN 2021 AND 2022
)
SELECT
    ct.year AS "Year",
    CASE ct.month
        WHEN 4 THEN 'April'
        WHEN 5 THEN 'May'
        WHEN 6 THEN 'June'
    END AS "Month",
    ct.cities_added AS "Total Cities Added",
    ct.running_total AS "Running Cumulative Total",
    ROUND(((ct.cities_added - p.prev_cities_added) * 100.0 / p.prev_cities_added), 4) || '%' AS "Year-over-Year Growth Percentage (Monthly)",
    ROUND(((ct.running_total - p.prev_running_total) * 100.0 / p.prev_running_total), 4) || '%' AS "Year-over-Year Growth Percentage (Running Total)"
FROM cumulative_totals ct
JOIN prev_year_totals p
    ON ct.year = p.year AND ct.month = p.month
WHERE ct.year IN (2022, 2023)
ORDER BY ct.year, ct.month;