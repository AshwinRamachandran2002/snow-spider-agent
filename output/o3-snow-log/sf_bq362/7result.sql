WITH trips_2018 AS (  -- monthly trip counts for 2018
    SELECT
        "company",
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ("trip_start_timestamp" / 1000000)) AS month_start,
        COUNT(*) AS trips
    FROM CHICAGO.CHICAGO_TAXI_TRIPS.TAXI_TRIPS
    WHERE EXTRACT(year FROM TO_TIMESTAMP_NTZ("trip_start_timestamp" / 1000000)) = 2018
    GROUP BY "company", month_start
),
diffs AS (           -- month-to-month changes per company
    SELECT
        "company",
        month_start,
        trips,
        trips - LAG(trips) OVER (PARTITION BY "company" ORDER BY month_start) AS trip_increase
    FROM trips_2018
)
SELECT
    "company",
    MAX(trip_increase) AS max_monthly_increase
FROM diffs
WHERE trip_increase IS NOT NULL        -- exclude first month (no previous month to compare)
GROUP BY "company"
ORDER BY max_monthly_increase DESC NULLS LAST
LIMIT 3;