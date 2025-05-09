SELECT
  AVG(
    TIMESTAMP_DIFF(t.dropoff_datetime, t.pickup_datetime, SECOND) / 60.0
  ) AS avg_trip_duration_minutes
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS p
  ON p.zone_id = t.pickup_location_id
JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS d
  ON d.zone_id = t.dropoff_location_id
WHERE
  DATE(t.pickup_datetime) BETWEEN '2016-02-01' AND '2016-02-07'
  AND TIMESTAMP_DIFF(t.dropoff_datetime, t.pickup_datetime, SECOND) > 0       -- positive duration
  AND t.passenger_count > 3                                                   -- more than three passengers
  AND t.trip_distance >= 10                                                   -- at least ten miles
  AND LOWER(p.borough) = 'brooklyn'                                           -- pickup in Brooklyn
  AND LOWER(d.borough) = 'brooklyn';                                          -- dropoff in Brooklyn