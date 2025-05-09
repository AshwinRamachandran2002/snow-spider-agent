WITH trips AS (   -- add year-month key and convert duration to minutes
    SELECT
        TO_CHAR(TO_TIMESTAMP_NTZ("start_date"), 'YYYYMM')              AS "year_month",
        CAST("duration_sec" AS FLOAT) / 60.0                           AS "duration_minutes",
        "start_date"
    FROM SAN_FRANCISCO.SAN_FRANCISCO.BIKESHARE_TRIPS
),

ranked AS (        -- identify first and last trip (by start_date) per month
    SELECT
        "year_month",
        "duration_minutes",
        ROW_NUMBER() OVER (PARTITION BY "year_month" ORDER BY "start_date" ASC)  AS rn_first,
        ROW_NUMBER() OVER (PARTITION BY "year_month" ORDER BY "start_date" DESC) AS rn_last
    FROM trips
)

SELECT
    "year_month",
    MAX(CASE WHEN rn_first = 1 THEN "duration_minutes" END)  AS first_duration_minutes,
    MAX(CASE WHEN rn_last  = 1 THEN "duration_minutes" END)  AS last_duration_minutes,
    MAX("duration_minutes")                                 AS highest_duration_minutes,
    MIN("duration_minutes")                                 AS lowest_duration_minutes
FROM ranked
GROUP BY "year_month"
ORDER BY "year_month";