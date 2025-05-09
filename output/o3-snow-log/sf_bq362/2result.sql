WITH trip2018 AS (
    SELECT
        "company",
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ("trip_start_timestamp" / 1000000)) AS "month_start"
    FROM CHICAGO.CHICAGO_TAXI_TRIPS.TAXI_TRIPS
    WHERE EXTRACT(year FROM TO_TIMESTAMP_NTZ("trip_start_timestamp" / 1000000)) = 2018
      AND "company" IS NOT NULL
),
monthly_counts AS (
    SELECT
        "company",
        "month_start",
        COUNT(*) AS "trips"
    FROM trip2018
    GROUP BY "company", "month_start"
),
diffs AS (
    SELECT
        "company",
        "month_start",
        "trips",
        LAG("trips") OVER (PARTITION BY "company" ORDER BY "month_start") AS "prev_trips",
        "trips" - LAG("trips") OVER (PARTITION BY "company" ORDER BY "month_start") AS "diff"
    FROM monthly_counts
),
max_increase AS (
    SELECT
        "company",
        MAX("diff") AS "max_monthly_increase"
    FROM diffs
    WHERE "diff" IS NOT NULL
    GROUP BY "company"
)
SELECT
    "company",
    "max_monthly_increase"
FROM max_increase
WHERE "max_monthly_increase" > 0
ORDER BY "max_monthly_increase" DESC NULLS LAST
LIMIT 3;