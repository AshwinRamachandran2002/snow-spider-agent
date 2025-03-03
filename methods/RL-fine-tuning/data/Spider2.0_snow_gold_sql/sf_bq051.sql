WITH precipitation_data AS (
  SELECT "date", ("value" / 10) AS "precipitation_mm"
  FROM "NEW_YORK_GHCN"."GHCN_D"."GHCND_2016"
  WHERE "id" = 'USW00094728' AND "element" = 'PRCP' AND "qflag" IS NULL
),
daily_precipitation AS (
  SELECT "date",
    SUM("precipitation_mm") AS "total_precipitation"
  FROM precipitation_data
  GROUP BY "date"
),
trip_counts AS (
  SELECT DATE(TO_TIMESTAMP_LTZ("starttime" / 1000000)) AS "trip_date",
    COUNT(*) AS "daily_trips"
  FROM "NEW_YORK_GHCN"."NEW_YORK"."CITIBIKE_TRIPS"
  WHERE DATE(TO_TIMESTAMP_LTZ("starttime" / 1000000)) BETWEEN '2016-01-01' AND '2016-12-31'
  GROUP BY "trip_date"
),
rainy_days AS (
  SELECT "date"
  FROM daily_precipitation
  WHERE "total_precipitation" > 5
),
non_rainy_days AS (
  SELECT tc."trip_date" AS "date"
  FROM trip_counts tc
  LEFT JOIN rainy_days rd ON tc."trip_date" = rd."date"
  WHERE rd."date" IS NULL
)
SELECT 'Rainy' AS "Weather",
  ROUND(AVG(tc."daily_trips"), 4) AS "Average_Daily_Trips"
FROM trip_counts tc
JOIN rainy_days rd ON tc."trip_date" = rd."date"
GROUP BY "Weather"
UNION ALL
SELECT 'Non-Rainy' AS "Weather",
  ROUND(AVG(tc."daily_trips"), 4) AS "Average_Daily_Trips"
FROM trip_counts tc
JOIN non_rainy_days nrd ON tc."trip_date" = nrd."date"
GROUP BY "Weather";