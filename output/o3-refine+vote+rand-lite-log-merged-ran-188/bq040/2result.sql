WITH base AS (
  SELECT
    z.borough                                                  AS pickup_borough,
    t.tip_amount,
    t.total_amount
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`       AS z
    ON t.pickup_location_id = z.zone_id
  WHERE DATE(t.pickup_datetime) BETWEEN '2016-01-01' AND '2016-01-07'          -- week of interest
    AND t.dropoff_datetime > t.pickup_datetime                                 -- logical trip
    AND t.passenger_count > 0                                                  -- at least one rider
    AND t.trip_distance >= 0
    AND t.tip_amount   >= 0
    AND t.tolls_amount >= 0
    AND t.mta_tax      >= 0
    AND t.fare_amount  >= 0
    AND t.total_amount >= 0
    AND z.borough NOT IN ('EWR','Staten Island')                               -- exclude boroughs
), tip_rate AS (
  SELECT
    pickup_borough,
    SAFE_MULTIPLY(SAFE_DIVIDE(tip_amount, NULLIF(total_amount - tip_amount,0)),100) AS pct_tip
  FROM base
), classified AS (
  SELECT
    pickup_borough,
    CASE
      WHEN pct_tip IS NULL OR pct_tip = 0                       THEN '0% (no tip)'
      WHEN pct_tip <= 5                                         THEN 'Up to 5%'
      WHEN pct_tip > 5  AND pct_tip <= 10                       THEN '5% to 10%'
      WHEN pct_tip > 10 AND pct_tip <= 15                       THEN '10% to 15%'
      WHEN pct_tip > 15 AND pct_tip <= 20                       THEN '15% to 20%'
      WHEN pct_tip > 20 AND pct_tip <= 25                       THEN '20% to 25%'
      ELSE 'More than 25%'                                      END AS tip_category
  FROM tip_rate
), agg AS (
  SELECT
    pickup_borough,
    tip_category,
    COUNT(*) AS rides
  FROM classified
  GROUP BY pickup_borough, tip_category
), totals AS (
  SELECT pickup_borough, SUM(rides) AS total_rides
  FROM agg
  GROUP BY pickup_borough
)
SELECT
  a.pickup_borough,
  a.tip_category,
  ROUND(a.rides / t.total_rides, 4) AS proportion_of_rides
FROM agg AS a
JOIN totals AS t
  ON a.pickup_borough = t.pickup_borough
ORDER BY a.pickup_borough, a.tip_category;