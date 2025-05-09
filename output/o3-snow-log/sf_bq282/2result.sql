WITH station_districts AS (
    SELECT
        TO_VARCHAR("station_id")                       AS "station_id_str",
        TRY_TO_NUMBER("council_district")              AS "district_num"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS
    WHERE TRY_TO_NUMBER("council_district") IS NOT NULL          -- keep only rows with numeric districts
), mapped_trips AS (
    SELECT
        s_start."district_num" AS "council_district"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS t
    JOIN station_districts s_start
         ON TO_VARCHAR(t."start_station_id") = s_start."station_id_str"
    JOIN station_districts s_end
         ON TO_VARCHAR(t."end_station_id")   = s_end."station_id_str"
    WHERE TO_VARCHAR(t."start_station_id") <> TO_VARCHAR(t."end_station_id")  -- different stations
      AND s_start."district_num" = s_end."district_num"                       -- same council district
)
SELECT "council_district"
FROM (
    SELECT
        "council_district",
        COUNT(*) AS trip_count
    FROM mapped_trips
    GROUP BY "council_district"
)
ORDER BY trip_count DESC NULLS LAST
LIMIT 1;