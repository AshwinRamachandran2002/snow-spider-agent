WITH trips_per_day AS (
  SELECT
    DATEADD('second', "pickup_datetime" / 1000000, '1970-01-01')::DATE AS "date",
    COUNT(*) AS "trip_count"
  FROM "NEW_YORK"."NEW_YORK"."TLC_YELLOW_TRIPS_2016"
  GROUP BY "date"
  UNION ALL
  SELECT
    DATEADD('second', "pickup_datetime" / 1000000, '1970-01-01')::DATE AS "date",
    COUNT(*) AS "trip_count"
  FROM "NEW_YORK"."NEW_YORK"."TLC_GREEN_TRIPS_2016"
  GROUP BY "date"
  UNION ALL
  SELECT
    DATEADD('second', "pickup_datetime" / 1000000, '1970-01-01')::DATE AS "date",
    COUNT(*) AS "trip_count"
  FROM "NEW_YORK"."NEW_YORK"."TLC_FHV_TRIPS_2016"
  GROUP BY "date"
),
daily_trips AS (
  SELECT
    "date",
    SUM("trip_count") AS "total_trips"
  FROM trips_per_day
  GROUP BY "date"
),
precipitation AS (
  SELECT
    DATE("date") AS "date",
    MAX("value") AS "precip"
  FROM "NEW_YORK_GHCN"."GHCN_D"."GHCND_1764"
  WHERE "element" = 'PRCP'
  GROUP BY "date"
),
trips_with_precip AS (
  SELECT
    t."date",
    t."total_trips",
    COALESCE(p."precip", 0) AS "precip"
  FROM daily_trips t
  LEFT JOIN precipitation p ON t."date" = p."date"
),
trips_classified AS (
  SELECT
    "date",
    "total_trips",
    CASE WHEN "precip" > 5 THEN 'Rainy' ELSE 'Non-Rainy' END AS "Rain_Type"
  FROM trips_with_precip
)
SELECT
  "Rain_Type",
  ROUND(AVG("total_trips"), 4) AS "Average_Number_of_Trips"
FROM trips_classified
GROUP BY "Rain_Type";