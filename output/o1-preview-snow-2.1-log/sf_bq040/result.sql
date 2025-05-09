WITH filtered_trips AS (
  SELECT
    t.*,
    z."borough",
    z."zone_name",
    TO_TIMESTAMP_NTZ(t."pickup_datetime" / 1e6) AS "pickup_timestamp",
    TO_TIMESTAMP_NTZ(t."dropoff_datetime" / 1e6) AS "dropoff_timestamp"
  FROM
    "NEW_YORK_PLUS"."NEW_YORK_TAXI_TRIPS"."TLC_YELLOW_TRIPS_2016" t
    JOIN "NEW_YORK_PLUS"."NEW_YORK_TAXI_TRIPS"."TAXI_ZONE_GEOM" z
      ON t."pickup_location_id" = z."zone_id"
  WHERE
    TO_TIMESTAMP_NTZ(t."pickup_datetime" / 1e6) >= '2016-01-01'
    AND TO_TIMESTAMP_NTZ(t."pickup_datetime" / 1e6) < '2016-01-08'
    AND z."borough" != 'Staten Island'
    AND z."zone_name" != 'EWR'
    AND t."passenger_count" > 0
    AND t."trip_distance" >= 0
    AND t."tip_amount" >= 0
    AND t."tolls_amount" >= 0
    AND t."mta_tax" >= 0
    AND t."fare_amount" >= 0
    AND t."total_amount" >= 0
    AND t."passenger_count" IS NOT NULL
    AND t."trip_distance" IS NOT NULL
    AND t."tip_amount" IS NOT NULL
    AND t."tolls_amount" IS NOT NULL
    AND t."mta_tax" IS NOT NULL
    AND t."fare_amount" IS NOT NULL
    AND t."total_amount" IS NOT NULL
    AND TO_TIMESTAMP_NTZ(t."dropoff_datetime" / 1e6) >= TO_TIMESTAMP_NTZ(t."pickup_datetime" / 1e6)
),
trips_with_tip_rate AS (
  SELECT
    "borough",
    CASE WHEN "fare_amount" > 0 THEN ("tip_amount" / "fare_amount") * 100 ELSE NULL END AS "tip_rate"
  FROM
    filtered_trips
  WHERE
    "tip_rate" IS NOT NULL
),
categorized_trips AS (
  SELECT
    "borough",
    CASE
      WHEN "tip_rate" = 0 THEN 'no tip'
      WHEN "tip_rate" > 0 AND "tip_rate" <= 5 THEN 'Less than 5%'
      WHEN "tip_rate" > 5 AND "tip_rate" <= 10 THEN '5% to 10%'
      WHEN "tip_rate" > 10 AND "tip_rate" <= 15 THEN '10% to 15%'
      WHEN "tip_rate" > 15 AND "tip_rate" <= 20 THEN '15% to 20%'
      WHEN "tip_rate" > 20 AND "tip_rate" <= 25 THEN '20% to 25%'
      WHEN "tip_rate" > 25 THEN 'More than 25%'
      ELSE 'Unknown'
    END AS "tip_category"
  FROM
    trips_with_tip_rate
)
SELECT
  "borough",
  "tip_category",
  ROUND(
    COUNT(*) * 1.0 / SUM(COUNT(*)) OVER (PARTITION BY "borough"),
    4
  ) AS "proportion"
FROM
  categorized_trips
GROUP BY
  "borough",
  "tip_category"
ORDER BY
  "borough",
  "tip_category";