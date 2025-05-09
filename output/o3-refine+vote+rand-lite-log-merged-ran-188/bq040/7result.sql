/*  Tip‑rate distribution of NYC yellow‑taxi rides
    Jan 1 – Jan 7 2016  (pickup boroughs except EWR & Staten Island)            */

WITH trips AS (
  SELECT
    pickup_datetime,
    dropoff_datetime,
    passenger_count,
    trip_distance,
    tip_amount,
    tolls_amount,
    mta_tax,
    fare_amount,
    total_amount,
    CAST(pickup_location_id AS STRING) AS pickup_location_id
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016`
  WHERE pickup_datetime >= '2016-01-01'
    AND pickup_datetime <  '2016-01-08'                       -- Jan 1‑7 inclusive
    AND dropoff_datetime > pickup_datetime                    -- logical trip
    AND passenger_count > 0
    AND trip_distance >= 0
    AND tip_amount      >= 0
    AND tolls_amount    >= 0
    AND mta_tax         >= 0
    AND fare_amount     >= 0
    AND total_amount    >= 0
),

trips_with_borough AS (
  SELECT
    z.borough,
    t.*,
    -- tip % of pre‑tip amount
    CASE
      WHEN (total_amount - tip_amount) > 0
           THEN 100 * tip_amount / (total_amount - tip_amount)
    END AS tip_rate
  FROM trips t
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`  z
    ON t.pickup_location_id = z.zone_id
  WHERE z.borough NOT IN ('EWR', 'Staten Island')                -- requested filter
),

classified AS (
  SELECT
    borough,
    CASE
      WHEN tip_amount = 0                     THEN 'no tip'
      WHEN tip_rate <=  5                    THEN 'Less than 5%'
      WHEN tip_rate <= 10                    THEN '5% to 10%'
      WHEN tip_rate <= 15                    THEN '10% to 15%'
      WHEN tip_rate <= 20                    THEN '15% to 20%'
      WHEN tip_rate <= 25                    THEN '20% to 25%'
      ELSE                                        'More than 25%'
    END AS tip_category
  FROM trips_with_borough
),

category_counts AS (
  SELECT borough, tip_category, COUNT(*) AS rides
  FROM   classified
  GROUP  BY borough, tip_category
),

borough_totals AS (
  SELECT borough, SUM(rides) AS total_rides
  FROM   category_counts
  GROUP  BY borough
)

SELECT
  c.borough,
  c.tip_category,
  ROUND(c.rides / t.total_rides, 4) AS proportion
FROM   category_counts  c
JOIN   borough_totals   t USING (borough)
ORDER  BY
  c.borough,
  CASE c.tip_category                         -- ensure logical ordering
    WHEN 'no tip'         THEN 1
    WHEN 'Less than 5%'   THEN 2
    WHEN '5% to 10%'      THEN 3
    WHEN '10% to 15%'     THEN 4
    WHEN '15% to 20%'     THEN 5
    WHEN '20% to 25%'     THEN 6
    ELSE                       7
  END;