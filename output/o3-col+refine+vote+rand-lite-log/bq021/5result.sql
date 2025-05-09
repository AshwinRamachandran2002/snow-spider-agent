-- Which of the 20 most-frequent 2016 Citi Bike routes is (a) faster than yellow taxis
-- on the same 3-dec-rounded origin/destination grid and (b) has the longest
-- average bike travel time?  Return the start-station name.

WITH top_routes AS (                      -- 1) 20 busiest Citi Bike routes in 2016
  SELECT
    start_station_id,
    end_station_id
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2016
  GROUP BY 1, 2
  ORDER BY COUNT(*) DESC
  LIMIT 20
),

bike_stats AS (                           -- 2) Avg. bike mins & 3-dec co-ordinates
  SELECT
    start_station_id,
    end_station_id,
    ROUND(start_station_latitude , 3) AS pu_lat,
    ROUND(start_station_longitude, 3) AS pu_lon,
    ROUND(end_station_latitude   , 3) AS do_lat,
    ROUND(end_station_longitude  , 3) AS do_lon,
    AVG(tripduration) / 60              AS avg_bike_min
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2016
  GROUP BY 1,2,3,4,5,6
),

taxi_stats AS (                           -- 3) Avg. taxi mins on same 3-dec grid
  SELECT
    ROUND(pickup_latitude , 3)  AS pu_lat,
    ROUND(pickup_longitude, 3)  AS pu_lon,
    ROUND(dropoff_latitude, 3)  AS do_lat,
    ROUND(dropoff_longitude, 3) AS do_lon,
    AVG( TIMESTAMP_DIFF(dropoff_datetime,
                         pickup_datetime,
                         SECOND) ) / 60  AS avg_taxi_min
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2016`
  WHERE pickup_datetime  IS NOT NULL
    AND dropoff_datetime IS NOT NULL
    AND TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, SECOND) > 0
  GROUP BY 1,2,3,4
),

station_names AS (                        -- 4) Helper to map id → name
  SELECT DISTINCT
    start_station_id,
    start_station_name
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2016
),

ranked_routes AS (                        -- 5) Keep top-20 routes where bikes are faster
  SELECT
    bs.*,
    ts.avg_taxi_min
  FROM bike_stats       AS bs
  JOIN taxi_stats       AS ts
    ON ts.pu_lat = bs.pu_lat AND ts.pu_lon = bs.pu_lon
   AND ts.do_lat = bs.do_lat AND ts.do_lon = bs.do_lon
  JOIN top_routes       AS tr
    ON tr.start_station_id = bs.start_station_id
   AND tr.end_station_id   = bs.end_station_id
  WHERE bs.avg_bike_min < ts.avg_taxi_min         -- bikes beat taxis here
)

SELECT sn.start_station_name                      -- 6) final answer
FROM ranked_routes AS rr
JOIN station_names  AS sn USING (start_station_id)
ORDER BY rr.avg_bike_min DESC                     -- longest (yet faster) bike time
LIMIT 1;