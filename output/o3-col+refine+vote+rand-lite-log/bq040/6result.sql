-- Proportion of rides in each tip-percentage bucket (per pickup borough)
-- NYC yellow taxis, 1–7 Jan 2016, after quality filters and borough exclusions
WITH valid_trips AS (   -- apply all data-quality and date filters
  SELECT
    pickup_location_id,
    SAFE_DIVIDE(tip_amount ,
                NULLIF(total_amount - tip_amount , 0)) * 100 AS tip_pct
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016`
  WHERE DATE(pickup_datetime) BETWEEN '2016-01-01' AND '2016-01-07'
    AND dropoff_datetime > pickup_datetime          -- logical trip
    AND passenger_count > 0
    AND trip_distance >= 0
    AND fare_amount   >= 0
    AND tip_amount    >= 0
    AND tolls_amount  >= 0
    AND mta_tax       >= 0
    AND total_amount  >= 0
),
bucketed AS (          -- add borough & tip bucket, drop EWR / Staten Island
  SELECT
    z.borough AS pickup_borough,
    CASE
      WHEN tip_pct IS NULL OR tip_pct = 0            THEN 'no tip'
      WHEN tip_pct  >  0 AND tip_pct <=  5           THEN 'Less than 5%'
      WHEN tip_pct  >  5 AND tip_pct <= 10           THEN '5% to 10%'
      WHEN tip_pct  > 10 AND tip_pct <= 15           THEN '10% to 15%'
      WHEN tip_pct  > 15 AND tip_pct <= 20           THEN '15% to 20%'
      WHEN tip_pct  > 20 AND tip_pct <= 25           THEN '20% to 25%'
      ELSE                                             'More than 25%'
    END AS tip_bucket
  FROM valid_trips v
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` z
    ON v.pickup_location_id = z.zone_id
  WHERE LOWER(z.borough) NOT IN ('ewr', 'staten island')
),
borough_totals AS (    -- total rides per eligible pickup borough
  SELECT pickup_borough, COUNT(*) AS total_trips
  FROM bucketed
  GROUP BY pickup_borough
)

SELECT
  b.pickup_borough,
  b.tip_bucket,
  ROUND(COUNT(*) / t.total_trips, 4) AS proportion_of_rides
FROM bucketed b
JOIN borough_totals t
  ON b.pickup_borough = t.pickup_borough
GROUP BY b.pickup_borough, b.tip_bucket, t.total_trips
ORDER BY b.pickup_borough, b.tip_bucket;