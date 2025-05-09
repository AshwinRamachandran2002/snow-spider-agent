WITH monthly_trip_counts AS (
    SELECT
        "company",
        DATE_TRUNC('month', TO_TIMESTAMP("trip_start_timestamp" / 1000000)) AS month_start,
        COUNT(*) AS trips_in_month
    FROM CHICAGO.CHICAGO_TAXI_TRIPS.TAXI_TRIPS
    WHERE DATE_PART('year', TO_TIMESTAMP("trip_start_timestamp" / 1000000)) = 2018
    GROUP BY
        "company",
        month_start
),
month_differences AS (
    SELECT
        "company",
        month_start,
        trips_in_month,
        trips_in_month 
          - LAG(trips_in_month) OVER (PARTITION BY "company" ORDER BY month_start) AS trip_increase
    FROM monthly_trip_counts
),
company_max_increase AS (
    SELECT
        "company",
        MAX(trip_increase) AS max_monthly_increase
    FROM month_differences
    WHERE trip_increase IS NOT NULL
    GROUP BY "company"
)
SELECT
    "company",
    max_monthly_increase
FROM company_max_increase
ORDER BY
    max_monthly_increase DESC NULLS LAST
LIMIT 3;