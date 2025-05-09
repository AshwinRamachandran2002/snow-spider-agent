WITH monthly_trip_counts AS (
    SELECT
        "company",
        EXTRACT(MONTH FROM TO_TIMESTAMP("trip_start_timestamp" / 1000000)) AS month,
        COUNT(*) AS "trip_count"
    FROM CHICAGO.CHICAGO_TAXI_TRIPS.TAXI_TRIPS
    WHERE YEAR(TO_TIMESTAMP("trip_start_timestamp" / 1000000)) = 2018
        AND "company" IS NOT NULL
    GROUP BY "company", EXTRACT(MONTH FROM TO_TIMESTAMP("trip_start_timestamp" / 1000000))
),
monthly_differences AS (
    SELECT
        "company" AS Company,
        LAG(month) OVER (PARTITION BY "company" ORDER BY month) AS Month_Start,
        month AS Month_End,
        LAG("trip_count") OVER (PARTITION BY "company" ORDER BY month) AS Trip_Count_Start,
        "trip_count" AS Trip_Count_End,
        "trip_count" - LAG("trip_count") OVER (PARTITION BY "company" ORDER BY month) AS Increase_in_Trip_Numbers
    FROM monthly_trip_counts
)
SELECT
    Company,
    Month_Start,
    Month_End,
    Increase_in_Trip_Numbers
FROM monthly_differences
WHERE Increase_in_Trip_Numbers > 0
ORDER BY Increase_in_Trip_Numbers DESC NULLS LAST, Company, Month_Start
LIMIT 3;