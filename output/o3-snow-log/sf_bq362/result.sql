WITH trips_2018 AS (
    SELECT
        "company",
        DATE_TRUNC('month', TO_TIMESTAMP("trip_start_timestamp" / 1000000)) AS month_start
    FROM CHICAGO.CHICAGO_TAXI_TRIPS.TAXI_TRIPS
    WHERE YEAR(TO_TIMESTAMP("trip_start_timestamp" / 1000000)) = 2018
),
monthly_counts AS (
    SELECT
        "company",
        month_start,
        COUNT(*) AS trip_count
    FROM trips_2018
    GROUP BY
        "company",
        month_start
),
diffs AS (
    SELECT
        "company",
        month_start,
        trip_count,
        CASE
            WHEN trip_count - LAG(trip_count) OVER (PARTITION BY "company" ORDER BY month_start) > 0
            THEN trip_count - LAG(trip_count) OVER (PARTITION BY "company" ORDER BY month_start)
        END AS positive_increase
    FROM monthly_counts
),
max_increase AS (
    SELECT
        "company",
        MAX(positive_increase) AS max_monthly_increase
    FROM diffs
    GROUP BY
        "company"
    HAVING MAX(positive_increase) IS NOT NULL
)
SELECT
    "company",
    max_monthly_increase
FROM max_increase
ORDER BY
    max_monthly_increase DESC NULLS LAST
LIMIT 3;