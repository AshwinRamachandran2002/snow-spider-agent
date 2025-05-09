WITH trip_data AS (
  SELECT
    z."borough",
    CASE
      WHEN ((t."tip_amount" / NULLIF((t."total_amount" - t."tip_amount"), 0)) * 100) = 0 THEN 'no tip'
      WHEN ((t."tip_amount" / NULLIF((t."total_amount" - t."tip_amount"), 0)) * 100) > 0 AND ((t."tip_amount" / (t."total_amount" - t."tip_amount")) * 100) <= 5 THEN 'Less than 5%'
      WHEN ((t."tip_amount" / (t."total_amount" - t."tip_amount")) * 100) > 5 AND ((t."tip_amount" / (t."total_amount" - t."tip_amount")) * 100) <= 10 THEN '5% to 10%'
      WHEN ((t."tip_amount" / (t."total_amount" - t."tip_amount")) * 100) > 10 AND ((t."tip_amount" / (t."total_amount" - t."tip_amount")) * 100) <= 15 THEN '10% to 15%'
      WHEN ((t."tip_amount" / (t."total_amount" - t."tip_amount")) * 100) > 15 AND ((t."tip_amount" / (t."total_amount" - t."tip_amount")) * 100) <= 20 THEN '15% to 20%'
      WHEN ((t."tip_amount" / (t."total_amount" - t."tip_amount")) * 100) > 20 AND ((t."tip_amount" / (t."total_amount" - t."tip_amount")) * 100) <= 25 THEN '20% to 25%'
      WHEN ((t."tip_amount" / (t."total_amount" - t."tip_amount")) * 100) > 25 THEN 'More than 25%'
      ELSE 'Unknown'
    END AS "tip_category"
  FROM
    "NEW_YORK_PLUS"."NEW_YORK_TAXI_TRIPS"."TLC_YELLOW_TRIPS_2016" t
  JOIN
    "NEW_YORK_PLUS"."NEW_YORK_TAXI_TRIPS"."TAXI_ZONE_GEOM" z
    ON t."pickup_location_id" = z."zone_id"
  WHERE
    TO_TIMESTAMP_NTZ(t."pickup_datetime" / 1e6) >= '2016-01-01'
    AND TO_TIMESTAMP_NTZ(t."pickup_datetime" / 1e6) < '2016-01-08'
    AND z."borough" != 'Staten Island'
    AND z."zone_name" != 'EWR'
    AND t."dropoff_datetime" > t."pickup_datetime"
    AND t."passenger_count" > 0
    AND t."trip_distance" >= 0
    AND t."tip_amount" >= 0
    AND t."tolls_amount" >= 0
    AND t."mta_tax" >= 0
    AND t."fare_amount" >= 0
    AND t."total_amount" >= 0
    AND (t."total_amount" - t."tip_amount") > 0
)
SELECT
  trip_data."borough",
  trip_data."tip_category",
  ROUND(
    COUNT(*)::DECIMAL / SUM(COUNT(*)) OVER (PARTITION BY trip_data."borough"),
    4
  ) AS "proportion"
FROM
  trip_data
GROUP BY
  trip_data."borough",
  trip_data."tip_category"
ORDER BY
  trip_data."borough",
  trip_data."tip_category";