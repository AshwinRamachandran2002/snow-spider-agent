WITH active_stations AS (
    SELECT 
        "station_id",
        "council_district"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS
    WHERE UPPER("status") = 'ACTIVE'
      AND "council_district" IS NOT NULL
), 
trip_counts AS (
    SELECT
        s_start."council_district" AS district,
        COUNT(*) AS trip_cnt
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS t
    JOIN active_stations s_start
        ON t."start_station_id" = s_start."station_id"
    JOIN active_stations s_end
        ON TRY_CAST(t."end_station_id" AS NUMBER) = s_end."station_id"
    WHERE s_start."council_district" = s_end."council_district"
      AND t."start_station_id" <> TRY_CAST(t."end_station_id" AS NUMBER)
    GROUP BY s_start."council_district"
)
SELECT district
FROM trip_counts
ORDER BY trip_cnt DESC NULLS LAST
LIMIT 1;