WITH monthly_trips AS (
    SELECT
        "company",
        EXTRACT(MONTH FROM TO_TIMESTAMP_LTZ("trip_start_timestamp" / 1000000)) AS "month",
        COUNT(*) AS "num_trips"
    FROM
        CHICAGO.CHICAGO_TAXI_TRIPS.TAXI_TRIPS
    WHERE
        EXTRACT(YEAR FROM TO_TIMESTAMP_LTZ("trip_start_timestamp" / 1000000)) = 2018
        AND "company" IS NOT NULL
    GROUP BY
        "company",
        "month"
),
monthly_increase AS (
    SELECT
        "company",
        LAG("month") OVER (PARTITION BY "company" ORDER BY "month") AS "month_start",
        "month" AS "month_end",
        ("num_trips" - LAG("num_trips") OVER (PARTITION BY "company" ORDER BY "month")) AS "trip_increase"
    FROM
        monthly_trips
)
SELECT
    "company",
    "month_start",
    "month_end",
    "trip_increase"
FROM
    monthly_increase
WHERE
    "trip_increase" IS NOT NULL
    AND "trip_increase" > 0
ORDER BY
    "trip_increase" DESC NULLS LAST
LIMIT 3;