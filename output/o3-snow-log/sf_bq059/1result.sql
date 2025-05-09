SELECT
    ROUND(
        MAX(
            (
                2 * 6371000 * ASIN(  -- Haversine distance (metres)
                    SQRT(
                        POW(SIN(RADIANS(("end_station_latitude"  - "start_station_latitude") ) / 2), 2) +
                        COS(RADIANS("start_station_latitude")) *
                        COS(RADIANS("end_station_latitude"))  *
                        POW(SIN(RADIANS(("end_station_longitude" - "start_station_longitude") ) / 2), 2)
                    )
                )
            )
            / NULLIF("duration_sec", 0)          -- divide by trip duration (seconds) → m/s
        )
    , 1)                                         -- round to 1 decimal place
    AS "highest_avg_speed_mps"
FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS
WHERE ("start_station_name" ILIKE '%berkeley%' 
       OR "end_station_name"   ILIKE '%berkeley%')   -- Berkeley trips
  AND "duration_sec" > 0                             -- avoid divide-by-zero
  AND ( 2 * 6371000 * ASIN(
          SQRT(
              POW(SIN(RADIANS(("end_station_latitude"  - "start_station_latitude") ) / 2), 2) +
              COS(RADIANS("start_station_latitude")) *
              COS(RADIANS("end_station_latitude"))  *
              POW(SIN(RADIANS(("end_station_longitude" - "start_station_longitude") ) / 2), 2)
          )
      )
    ) > 1000;                                        -- only trips > 1 000 m