WITH trips AS (
    SELECT
        /* derive year-month key in YYYYMM format */
        TO_CHAR(
            TO_TIMESTAMP("start_date" / 1000000),   -- epoch µs  ➜ timestamp
            'YYYYMM'
        )                                AS "year_month",
        "start_date",
        /* convert trip duration to minutes, keep 4-decimal precision */
        ROUND("duration_sec" / 60.0, 4)  AS "duration_min"
    FROM SAN_FRANCISCO.SAN_FRANCISCO.BIKESHARE_TRIPS
),
stats AS (
    SELECT
        "year_month",
        /* earliest trip of the month */
        FIRST_VALUE("duration_min")
            OVER (PARTITION BY "year_month" ORDER BY "start_date" ASC)  AS "first_duration_min",
        /* latest trip of the month */
        FIRST_VALUE("duration_min")
            OVER (PARTITION BY "year_month" ORDER BY "start_date" DESC) AS "last_duration_min",
        /* highest & lowest durations in the month */
        MAX("duration_min") OVER (PARTITION BY "year_month")            AS "max_duration_min",
        MIN("duration_min") OVER (PARTITION BY "year_month")            AS "min_duration_min",
        /* helper to keep one row per month */
        ROW_NUMBER() OVER (PARTITION BY "year_month" ORDER BY "start_date") AS "rn"
    FROM trips
)
SELECT
    "year_month",
    "first_duration_min",
    "last_duration_min",
    "max_duration_min",
    "min_duration_min"
FROM stats
WHERE "rn" = 1                 -- keep a single row per YYYYMM
ORDER BY "year_month";