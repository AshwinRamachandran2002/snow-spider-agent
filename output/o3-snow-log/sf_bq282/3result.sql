WITH active_stations AS (
    SELECT
        "station_id"                        AS station_id_num,
        "council_district"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS
    WHERE LOWER("status") = 'active'
),
trip_districts AS (
    SELECT
        t."trip_id",
        s_start."council_district" AS start_district,
        s_end."council_district"   AS end_district
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS t
    JOIN active_stations s_start
      ON t."start_station_id" = s_start.station_id_num
    JOIN active_stations s_end
      ON TRY_TO_NUMBER(t."end_station_id") = s_end.station_id_num
    WHERE s_start."council_district" IS NOT NULL
      AND s_start."council_district" = s_end."council_district"   -- same district
      AND t."start_station_id" <> TRY_TO_NUMBER(t."end_station_id") -- different stations
)
SELECT 
    start_district AS "COUNCIL_DISTRICT_CODE"
FROM trip_districts
GROUP BY start_district
ORDER BY COUNT(*) DESC NULLS LAST
LIMIT 1;