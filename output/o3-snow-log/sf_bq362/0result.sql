WITH monthly_trips AS (
    SELECT
        "company",
        EXTRACT(MONTH FROM TO_TIMESTAMP("trip_start_timestamp" / 1000000)) AS month,
        COUNT(*) AS trips
    FROM CHICAGO.CHICAGO_TAXI_TRIPS.TAXI_TRIPS
    WHERE EXTRACT(YEAR FROM TO_TIMESTAMP("trip_start_timestamp" / 1000000)) = 2018
      AND "company" IS NOT NULL
    GROUP BY "company", month
),
monthly_with_lag AS (
    SELECT
        "company",
        month,
        trips,
        LAG(trips) OVER (PARTITION BY "company" ORDER BY month) AS prev_trips,
        trips - LAG(trips) OVER (PARTITION BY "company" ORDER BY month) AS increase
    FROM monthly_trips
),
max_increase_per_company AS (
    SELECT
        "company",
        MAX(increase) AS max_increase
    FROM monthly_with_lag
    WHERE increase IS NOT NULL
    GROUP BY "company"
)
SELECT
    "company",
    max_increase
FROM max_increase_per_company
ORDER BY max_increase DESC NULLS LAST
LIMIT 3;