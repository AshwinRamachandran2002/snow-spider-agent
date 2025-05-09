SELECT
  borough,
  tip_category,
  ROUND(COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY borough), 4) AS proportion
FROM (
  SELECT
    sub.borough,
    CASE
      WHEN sub.tip_amount = 0 THEN 'no tip'
      WHEN sub.tip_rate > 0 AND sub.tip_rate <= 5 THEN 'Less than 5%'
      WHEN sub.tip_rate > 5 AND sub.tip_rate <= 10 THEN '5% to 10%'
      WHEN sub.tip_rate > 10 AND sub.tip_rate <= 15 THEN '10% to 15%'
      WHEN sub.tip_rate > 15 AND sub.tip_rate <= 20 THEN '15% to 20%'
      WHEN sub.tip_rate > 20 AND sub.tip_rate <= 25 THEN '20% to 25%'
      WHEN sub.tip_rate > 25 THEN 'More than 25%'
      ELSE 'Unknown'
    END AS tip_category
  FROM (
    SELECT
      t.tip_amount,
      t.total_amount,
      z.borough,
      (t.tip_amount / NULLIF(t.total_amount - t.tip_amount, 0)) * 100 AS tip_rate
    FROM
      `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
    JOIN
      `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS z
    ON
      t.pickup_location_id = z.zone_id
    WHERE
      DATE(t.pickup_datetime) BETWEEN '2016-01-01' AND '2016-01-07'
      AND z.borough NOT IN ('EWR', 'Staten Island')
      AND t.dropoff_datetime > t.pickup_datetime
      AND t.passenger_count IS NOT NULL AND t.passenger_count > 0
      AND t.trip_distance IS NOT NULL AND t.trip_distance >= 0
      AND t.tip_amount IS NOT NULL AND t.tip_amount >= 0
      AND t.tolls_amount IS NOT NULL AND t.tolls_amount >= 0
      AND t.mta_tax IS NOT NULL AND t.mta_tax >= 0
      AND t.fare_amount IS NOT NULL AND t.fare_amount >= 0
      AND t.total_amount IS NOT NULL AND t.total_amount >= 0
  ) AS sub
)
GROUP BY
  borough,
  tip_category
ORDER BY
  borough,
  tip_category;