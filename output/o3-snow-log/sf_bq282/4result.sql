SELECT district
FROM (
    SELECT
        ss."council_district" AS district,
        COUNT(*)              AS trip_count
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS    t
    JOIN AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS ss
         ON t."start_station_id" = ss."station_id"
    JOIN AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS es
         ON TRY_TO_NUMBER(t."end_station_id") = es."station_id"
    WHERE t."start_station_id" IS NOT NULL
      AND t."end_station_id"   IS NOT NULL
      AND TRY_TO_NUMBER(t."end_station_id") IS NOT NULL          -- ensure numeric
      AND t."start_station_id" <> TRY_TO_NUMBER(t."end_station_id") -- different stations
      AND ss."council_district" IS NOT NULL
      AND ss."council_district" = es."council_district"          -- same district
    GROUP BY ss."council_district"
    ORDER BY trip_count DESC NULLS LAST
    LIMIT 1
);