WITH trips_2018 AS (
    SELECT
        "company",
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ("trip_start_timestamp" / 1000000)) AS trip_month
    FROM CHICAGO.CHICAGO_TAXI_TRIPS.TAXI_TRIPS
    WHERE EXTRACT(year FROM TO_TIMESTAMP_NTZ("trip_start_timestamp" / 1000000)) = 2018
),
monthly_counts AS (
    SELECT
        "company",
        trip_month,
        COUNT(*) AS trip_count
    FROM trips_2018
    GROUP BY "company", trip_month
),
monthly_diffs AS (
    SELECT
        cur."company",
        cur.trip_month,
        cur.trip_count - COALESCE(prev.trip_count, 0) AS trip_increase
    FROM monthly_counts cur
    LEFT JOIN monthly_counts prev
           ON cur."company" = prev."company"
          AND prev.trip_month = DATEADD(month, -1, cur.trip_month)
),
max_increase_per_company AS (
    SELECT
        "company",
        MAX(trip_increase) AS max_monthly_increase
    FROM monthly_diffs
    GROUP BY "company"
)
SELECT
    "company",
    max_monthly_increase
FROM max_increase_per_company
ORDER BY max_monthly_increase DESC NULLS LAST
LIMIT 3;