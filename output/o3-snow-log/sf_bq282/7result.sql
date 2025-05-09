WITH trip_ids AS (
    /* keep only trips whose start & end stations are known and different */
    SELECT
        "trip_id",
        "start_station_id"                                             AS start_station_id,
        TRY_TO_NUMBER("end_station_id")                                AS end_station_id
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS
    WHERE "start_station_id" IS NOT NULL
      AND TRY_TO_NUMBER("end_station_id") IS NOT NULL
      AND "start_station_id" <> TRY_TO_NUMBER("end_station_id")
), trip_districts AS (
    /* attach council-districts for both start and end stations */
    SELECT
        t."trip_id",
        ss."council_district"  AS start_cd,
        es."council_district"  AS end_cd
    FROM trip_ids t
    JOIN AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS ss
         ON t.start_station_id = ss."station_id"
    JOIN AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS es
         ON t.end_station_id   = es."station_id"
    WHERE ss."council_district" IS NOT NULL
      AND es."council_district" IS NOT NULL
      AND ss."council_district" = es."council_district"
)
SELECT
    start_cd AS council_district
FROM trip_districts
GROUP BY start_cd
ORDER BY COUNT(*) DESC NULLS LAST
LIMIT 1;