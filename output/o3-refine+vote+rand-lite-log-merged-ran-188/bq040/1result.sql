-- Tip‐rate distribution for NYC yellow taxis, Jan 1–7 2016
WITH base AS (
  SELECT
    g.borough                         AS pickup_borough,
    t.tip_amount,
    t.total_amount,
    -- percentage of tip relative to pre‑tip total
    SAFE_DIVIDE(100 * t.tip_amount,
                NULLIF(t.total_amount - t.tip_amount, 0)) AS tip_pct
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`           AS g
        ON t.pickup_location_id = g.zone_id
  WHERE
        t.pickup_datetime >= '2016-01-01'         -- inclusive
    AND t.pickup_datetime <  '2016-01-08'         -- exclusive → up to Jan 7
    AND g.borough NOT IN ('EWR', 'Staten Island') -- exclude requested areas
    AND t.dropoff_datetime > t.pickup_datetime    -- logical trip
    AND t.passenger_count > 0
    AND t.trip_distance     >= 0
    AND t.tip_amount        >= 0
    AND t.tolls_amount      >= 0
    AND t.mta_tax           >= 0
    AND t.fare_amount       >= 0
    AND t.total_amount      >= 0
),
categorized AS (              -- place every ride in a tip bucket
  SELECT
    pickup_borough,
    CASE
      WHEN tip_amount = 0                       THEN '0% (no tip)'
      WHEN tip_pct IS NULL                      THEN '0% (no tip)'
      WHEN tip_pct <=  5                        THEN 'up to 5%'
      WHEN tip_pct >   5 AND tip_pct <= 10      THEN '5% to 10%'
      WHEN tip_pct >  10 AND tip_pct <= 15      THEN '10% to 15%'
      WHEN tip_pct >  15 AND tip_pct <= 20      THEN '15% to 20%'
      WHEN tip_pct >  20 AND tip_pct <= 25      THEN '20% to 25%'
      ELSE                                            'more than 25%'
    END AS tip_category
  FROM base
),
counts AS (
  SELECT
    pickup_borough,
    tip_category,
    COUNT(*) AS rides
  FROM categorized
  GROUP BY pickup_borough, tip_category
),
totals AS (                   -- total rides in each pickup borough
  SELECT
    pickup_borough,
    SUM(rides) AS total_rides
  FROM counts
  GROUP BY pickup_borough
)
SELECT
  c.pickup_borough,
  c.tip_category,
  ROUND(c.rides / t.total_rides, 4) AS proportion_of_rides
FROM counts  AS c
JOIN totals  AS t
  ON c.pickup_borough = t.pickup_borough
ORDER BY
  c.pickup_borough,
  -- preserve logical bucket ordering
  CASE c.tip_category
       WHEN '0% (no tip)'      THEN 1
       WHEN 'up to 5%'         THEN 2
       WHEN '5% to 10%'        THEN 3
       WHEN '10% to 15%'       THEN 4
       WHEN '15% to 20%'       THEN 5
       WHEN '20% to 25%'       THEN 6
       ELSE                         7
  END;