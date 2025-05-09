WITH "TripData" AS (
    SELECT
        TO_CHAR(TO_TIMESTAMP_NTZ("start_date" / 1000000), 'YYYYMM') AS "YearMonth",
        "start_date",
        FLOOR("duration_sec" / 60) AS "DurationMinutes",
        ROW_NUMBER() OVER (
            PARTITION BY "YearMonth"
            ORDER BY "start_date" ASC NULLS LAST, "trip_id" ASC
        ) AS "RowNumAsc",
        ROW_NUMBER() OVER (
            PARTITION BY "YearMonth"
            ORDER BY "start_date" DESC NULLS LAST, "trip_id" ASC
        ) AS "RowNumDesc"
    FROM
        "SAN_FRANCISCO"."SAN_FRANCISCO"."BIKESHARE_TRIPS"
    WHERE
        "start_date" IS NOT NULL
)
SELECT
    "YearMonth",
    MAX(CASE WHEN "RowNumAsc" = 1 THEN "DurationMinutes" END) AS "FirstTripDurationMinutes",
    MAX(CASE WHEN "RowNumDesc" = 1 THEN "DurationMinutes" END) AS "LastTripDurationMinutes",
    MAX("DurationMinutes") AS "HighestTripDurationMinutes",
    MIN("DurationMinutes") AS "LowestTripDurationMinutes"
FROM
    "TripData"
GROUP BY
    "YearMonth"
ORDER BY
    "YearMonth";