WITH trip_cte AS (
    SELECT
        s_start."council_district" AS district
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS              t
    JOIN AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS s_start
         ON t."start_station_id" = s_start."station_id"
    JOIN AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS s_end
         ON TRY_CAST(t."end_station_id" AS NUMBER) = s_end."station_id"
    WHERE s_start."status" = 'active'
      AND s_end."status"   = 'active'
      AND s_start."council_district" IS NOT NULL
      AND s_start."council_district" = s_end."council_district"
      AND t."start_station_id" <> TRY_CAST(t."end_station_id" AS NUMBER)
)

SELECT district
FROM (
    SELECT district,
           COUNT(*) AS trip_count
    FROM trip_cte
    GROUP BY district
    ORDER BY trip_count DESC NULLS LAST
    LIMIT 1
);