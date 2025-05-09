-- % of “no–tip” yellow‑taxi trips (Jan 1–7 2016) by pickup borough
WITH filtered_trips AS (
  SELECT
    tz.borough                                        AS pickup_borough,
    -- tip‑rate expressed in %; 0 when total_amount is 0 (or NULL)
    CASE
      WHEN SAFE_CAST(t.total_amount AS NUMERIC) IS NULL 
           OR SAFE_CAST(t.total_amount AS NUMERIC) = 0 THEN 0
      ELSE (SAFE_CAST(t.tip_amount AS NUMERIC) * 100) 
           / SAFE_CAST(t.total_amount AS NUMERIC)
    END                                               AS tip_rate
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
  LEFT JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`   AS tz
         ON CAST(t.pickup_location_id AS STRING) = tz.zone_id
  WHERE
        -- required 7‑day window (inclusive of Jan 7)
        t.pickup_datetime  >= '2016-01-01 00:00:00'
    AND t.pickup_datetime  <  '2016-01-08 00:00:00'
    AND t.dropoff_datetime >= '2016-01-01 00:00:00'
    AND t.dropoff_datetime <  '2016-01-08 00:00:00'
        -- drop‑off must be after pickup
    AND t.dropoff_datetime >  t.pickup_datetime
        -- basic trip‑quality filters
    AND t.passenger_count  >  0
    AND t.trip_distance    >= 0
    AND t.tip_amount       >= 0
    AND t.tolls_amount     >= 0
    AND t.mta_tax          >= 0
    AND t.fare_amount      >= 0
    AND t.total_amount     >= 0
)

SELECT
  COALESCE(pickup_borough, 'Unknown')                                    AS pickup_borough,
  ROUND(
        100 * SUM(CASE WHEN tip_rate = 0 THEN 1 ELSE 0 END)
        / COUNT(*)
       , 4)                                                              AS pct_no_tip
FROM filtered_trips
GROUP BY pickup_borough
ORDER BY pickup_borough;