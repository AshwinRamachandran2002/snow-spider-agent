WITH base AS (
  SELECT
    t.pickup_datetime,
    t.dropoff_datetime,
    t.passenger_count,
    t.trip_distance,
    t.tip_amount,
    t.tolls_amount,
    t.mta_tax,
    t.fare_amount,
    t.total_amount,
    z.borough              AS pickup_borough,
    -- tip percentage on the pre‑tip amount (= total minus tip),
    -- expressed as a percent.
    COALESCE(
      SAFE_DIVIDE(t.tip_amount ,
                  NULLIF(t.total_amount - t.tip_amount , 0)) * 100,
      0
    )                     AS tip_rate
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` t
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`        z
    ON z.zone_id = t.pickup_location_id
  WHERE DATE(t.pickup_datetime) BETWEEN '2016-01-01' AND '2016-01-07'
    AND t.dropoff_datetime > t.pickup_datetime
    AND t.passenger_count > 0
    AND t.trip_distance  >= 0
    AND t.tip_amount     >= 0
    AND t.tolls_amount   >= 0
    AND t.mta_tax        >= 0
    AND t.fare_amount    >= 0
    AND t.total_amount   >= 0
    AND z.borough NOT IN ('EWR','Staten Island')
),
labeled AS (
  SELECT
    pickup_borough,
    CASE
      WHEN tip_rate = 0                     THEN 'no tip'
      WHEN tip_rate <= 5                    THEN 'Less than 5%'
      WHEN tip_rate  > 5  AND tip_rate <=10 THEN '5% to 10%'
      WHEN tip_rate  >10  AND tip_rate <=15 THEN '10% to 15%'
      WHEN tip_rate  >15  AND tip_rate <=20 THEN '15% to 20%'
      WHEN tip_rate  >20  AND tip_rate <=25 THEN '20% to 25%'
      ELSE                                       'More than 25%'
    END AS tip_category
  FROM base
)
SELECT
  pickup_borough,
  tip_category,
  COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY pickup_borough) AS proportion
FROM labeled
GROUP BY
  pickup_borough,
  tip_category
ORDER BY
  pickup_borough,
  tip_category;