WITH
    current_year_data AS (
        SELECT
            CAST(strftime('%Y', "insert_date") AS INTEGER) AS "Year",
            strftime('%m', "insert_date") AS "Month",
            COUNT("city_id") AS "TotalCitiesAdded",
            SUM(COUNT("city_id")) OVER (
                PARTITION BY strftime('%Y', "insert_date")
                ORDER BY strftime('%m', "insert_date")
            ) AS "RunningCumulativeTotal"
        FROM "cities"
        WHERE
            strftime('%Y', "insert_date") IN ('2022', '2023') AND
            strftime('%m', "insert_date") BETWEEN '01' AND '06'
        GROUP BY "Year", "Month"
    ),
    current_data_filtered AS (
        SELECT *
        FROM current_year_data
        WHERE "Month" IN ('04', '05', '06')
    ),
    previous_year_data AS (
        SELECT
            CAST(strftime('%Y', "insert_date") AS INTEGER) + 1 AS "Year",
            strftime('%m', "insert_date") AS "Month",
            COUNT("city_id") AS "TotalCitiesAdded",
            SUM(COUNT("city_id")) OVER (
                PARTITION BY strftime('%Y', "insert_date")
                ORDER BY strftime('%m', "insert_date")
            ) AS "RunningCumulativeTotal"
        FROM "cities"
        WHERE
            strftime('%Y', "insert_date") IN ('2021', '2022') AND
            strftime('%m', "insert_date") BETWEEN '01' AND '06'
        GROUP BY strftime('%Y', "insert_date"), "Month"
    ),
    previous_data_filtered AS (
        SELECT *
        FROM previous_year_data
        WHERE "Month" IN ('04', '05', '06')
    )
SELECT
    c."Year",
    CASE c."Month"
        WHEN '04' THEN 'April'
        WHEN '05' THEN 'May'
        WHEN '06' THEN 'June'
    END AS "Month",
    c."TotalCitiesAdded" AS "Total Cities Added",
    c."RunningCumulativeTotal" AS "Running Cumulative Total",
    ROUND(((c."TotalCitiesAdded" - p."TotalCitiesAdded") * 100.0 / p."TotalCitiesAdded"), 4) || '%' AS "Year-over-Year Growth Percentage (Monthly)",
    ROUND(((c."RunningCumulativeTotal" - p."RunningCumulativeTotal") * 100.0 / p."RunningCumulativeTotal"), 4) || '%' AS "Year-over-Year Growth Percentage (Running Total)"
FROM current_data_filtered c
JOIN previous_data_filtered p
    ON c."Year" = p."Year" AND c."Month" = p."Month"
ORDER BY c."Year", c."Month";