-- Highest average speed (m/s, rounded to 1 decimal) for Berkeley-origin bike trips
-- whose straight-line distance exceeds 1 000 m
SELECT
  ROUND(
    MAX(                           -- highest average speed
      ( 6371000 * 2 * ASIN(        -- Haversine distance (metres)
          SQRT(
            POWER(SIN(RADIANS("end_station_latitude"  - "start_station_latitude") / 2), 2) +
            COS(RADIANS("start_station_latitude")) *
            COS(RADIANS("end_station_latitude")) *
            POWER(SIN(RADIANS("end_station_longitude" - "start_station_longitude") / 2), 2)
          )
        )
      ) 
      / NULLIF("duration_sec", 0)  -- divide by trip duration (sec) → m/s
    ), 
    1                              -- round to one decimal place
  ) AS "max_speed_m_s"
FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS
WHERE "start_station_latitude"  BETWEEN 37.85 AND 37.90      -- Berkeley lat bounds
  AND "start_station_longitude" BETWEEN -122.30 AND -122.25   -- Berkeley lon bounds
  AND ( 6371000 * 2 * ASIN(                                   -- require >1 000 m distance
          SQRT(
            POWER(SIN(RADIANS("end_station_latitude"  - "start_station_latitude") / 2), 2) +
            COS(RADIANS("start_station_latitude")) *
            COS(RADIANS("end_station_latitude")) *
            POWER(SIN(RADIANS("end_station_longitude" - "start_station_longitude") / 2), 2)
          )
        )
      ) > 1000;