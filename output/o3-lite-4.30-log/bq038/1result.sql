WITH loop_trips AS (                      -- 1. loop rides (start = end)
  SELECT
    start_station_id AS station_id,
    FLOOR(UNIX_SECONDS(starttime)/120) AS bucket_2min
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE start_station_id = end_station_id
),
group_windows AS (                        -- 2. 2‑min windows with ≥2 such rides
  SELECT
    station_id,
    bucket_2min
  FROM loop_trips
  GROUP BY station_id, bucket_2min
  HAVING COUNT(*) > 1
),
group_ride_trips AS (                     -- 3. every trip that belongs to a group window
  SELECT l.station_id
  FROM loop_trips       AS l
  JOIN group_windows    AS g USING (station_id, bucket_2min)
),
numerator AS (                            -- 4. # of group‑ride trips per station
  SELECT
    station_id,
    COUNT(*) AS group_ride_trips
  FROM group_ride_trips
  GROUP BY station_id
),
denominator AS (                          -- 5. total trips ending at each station
  SELECT
    end_station_id AS station_id,
    COUNT(*)        AS total_ending_trips
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE end_station_id IS NOT NULL
  GROUP BY station_id
),
ratio AS (                                -- 6. proportion = numerator / denominator
  SELECT
    d.station_id,
    SAFE_DIVIDE(IFNULL(n.group_ride_trips,0), d.total_ending_trips) AS group_ride_proportion
  FROM denominator AS d
  LEFT JOIN numerator AS n USING (station_id)
)
SELECT                                    -- 7. top‑10 stations by proportion
  r.station_id,
  COALESCE(s.name,'') AS station_name,
  ROUND(r.group_ride_proportion, 4) AS group_ride_proportion
FROM ratio AS r
LEFT JOIN `bigquery-public-data.new_york.citibike_stations` AS s
       ON SAFE_CAST(s.station_id AS INT64) = r.station_id
ORDER BY r.group_ride_proportion DESC, r.station_id
LIMIT 10;