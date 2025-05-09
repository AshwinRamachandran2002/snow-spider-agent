WITH trips_2018 AS (
    SELECT
        "company",
        DATE_TRUNC('month', TO_TIMESTAMP("trip_start_timestamp" / 1000000))     AS month_start,
        COUNT(*)                                                               AS trip_count
    FROM CHICAGO.CHICAGO_TAXI_TRIPS.TAXI_TRIPS
    WHERE EXTRACT(year FROM TO_TIMESTAMP("trip_start_timestamp" / 1000000)) = 2018
          AND "company" IS NOT NULL
    GROUP BY "company", month_start
),
month_diffs AS (
    SELECT
        "company",
        month_start,
        trip_count 
        - COALESCE(LAG(trip_count) OVER (PARTITION BY "company" ORDER BY month_start), 0) 
        AS diff
    FROM trips_2018
),
max_increase_per_company AS (
    SELECT
        "company",
        MAX(diff) AS max_monthly_increase
    FROM month_diffs
    WHERE diff > 0
    GROUP BY "company"
)
SELECT
    "company",
    max_monthly_increase
FROM max_increase_per_company
ORDER BY max_monthly_increase DESC NULLS LAST
LIMIT 3;