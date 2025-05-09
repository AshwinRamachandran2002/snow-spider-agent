WITH trip_monthly AS (
    SELECT
        TO_CHAR(TO_TIMESTAMP("start_date" / 1e6), 'YYYY-MM') AS "Month",
        "trip_id",
        "start_date",
        ("duration_sec" / 60.0) AS "duration_minutes",
        ROW_NUMBER() OVER (
            PARTITION BY TO_CHAR(TO_TIMESTAMP("start_date" / 1e6), 'YYYY-MM')
            ORDER BY "start_date" ASC NULLS LAST
        ) AS "rn_first",
        ROW_NUMBER() OVER (
            PARTITION BY TO_CHAR(TO_TIMESTAMP("start_date" / 1e6), 'YYYY-MM')
            ORDER BY "start_date" DESC NULLS LAST
        ) AS "rn_last"
    FROM
        "SAN_FRANCISCO"."SAN_FRANCISCO"."BIKESHARE_TRIPS"
),
first_last_trips AS (
    SELECT
        "Month",
        MAX(CASE WHEN "rn_first" = 1 THEN ROUND("duration_minutes", 4) END) AS "First_trip_duration_minutes",
        MAX(CASE WHEN "rn_last" = 1 THEN ROUND("duration_minutes", 4) END) AS "Last_trip_duration_minutes"
    FROM
        trip_monthly
    GROUP BY
        "Month"
),
max_min_durations AS (
    SELECT
        "Month",
        ROUND(MAX("duration_minutes"), 4) AS "Highest_trip_duration_minutes",
        ROUND(MIN("duration_minutes"), 4) AS "Lowest_trip_duration_minutes"
    FROM
        trip_monthly
    GROUP BY
        "Month"
)
SELECT
    fl."Month",
    fl."First_trip_duration_minutes",
    fl."Last_trip_duration_minutes",
    md."Highest_trip_duration_minutes",
    md."Lowest_trip_duration_minutes"
FROM
    first_last_trips fl
JOIN
    max_min_durations md ON fl."Month" = md."Month"
ORDER BY
    fl."Month";