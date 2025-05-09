-- Which 2016 Citi Bike route (among the 20 busiest) is still faster than Yellow cabs,
-- yet has the longest average bike time?  ──> return its start-station name
WITH bike_top20 AS (
  SELECT
      ROUND(start_station_latitude ,3) AS s_lat3,
      ROUND(start_station_longitude,3) AS s_lon3,
      ROUND(end_station_latitude   ,3) AS e_lat3,
      ROUND(end_station_longitude  ,3) AS e_lon3,
      ANY_VALUE(start_station_name)    AS start_station_name,
      COUNT(*)                         AS bike_trips,
      AVG(tripduration)                AS bike_avg_secs
  FROM  `bigquery-public-data.new_york.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime)=2016
  GROUP BY s_lat3,s_lon3,e_lat3,e_lon3
  ORDER BY bike_trips DESC
  LIMIT 20                                             -- “top 20 Citi Bike routes”
),
taxi_avg AS (
  SELECT
      ROUND(pickup_latitude ,3)  AS s_lat3,
      ROUND(pickup_longitude,3)  AS s_lon3,
      ROUND(dropoff_latitude,3)  AS e_lat3,
      ROUND(dropoff_longitude,3) AS e_lon3,
      AVG(TIMESTAMP_DIFF(dropoff_datetime,
                          pickup_datetime,SECOND))    AS taxi_avg_secs
  FROM  `bigquery-public-data.new_york.tlc_yellow_trips_2016`
  WHERE pickup_datetime  IS NOT NULL
    AND dropoff_datetime IS NOT NULL
  GROUP BY s_lat3,s_lon3,e_lat3,e_lon3
)

SELECT  b.start_station_name
FROM    bike_top20  AS b
JOIN    taxi_avg    AS t USING (s_lat3,s_lon3,e_lat3,e_lon3)
WHERE   b.bike_avg_secs < t.taxi_avg_secs            -- bike is faster
ORDER BY b.bike_avg_secs DESC                        -- but longest bike time
LIMIT   1;