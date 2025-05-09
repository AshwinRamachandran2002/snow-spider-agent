WITH trips_with_districts AS (
    SELECT 
        ss."council_district"          AS "start_district",
        es."council_district"          AS "end_district"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS bt
    JOIN AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS ss
          ON bt."start_station_id" = ss."station_id"
    JOIN AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS es
          ON TRY_TO_NUMBER(bt."end_station_id") = es."station_id"
    WHERE ss."council_district" IS NOT NULL
      AND es."council_district" IS NOT NULL
      AND ss."council_district" = es."council_district"          -- same district
      AND bt."start_station_id" <> TRY_TO_NUMBER(bt."end_station_id")  -- different stations
)

SELECT 
    "start_district" AS "council_district"
FROM trips_with_districts
GROUP BY "start_district"
ORDER BY COUNT(*) DESC NULLS LAST
LIMIT 1;