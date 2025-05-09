SELECT DATE_FROM_PARTS("year", "mo", "da") AS "Date",
       ROUND("temp", 4) AS "Temperature",
       ROUND(CAST("wdsp" AS FLOAT), 4) AS "Wind_Speed",
       ROUND("prcp", 4) AS "Precipitation"
FROM (
  SELECT "year", "mo", "da", "wban", "temp", "wdsp", "prcp"
  FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2011"
  UNION ALL
  SELECT "year", "mo", "da", "wban", "temp", "wdsp", "prcp"
  FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2012"
  UNION ALL
  SELECT "year", "mo", "da", "wban", "temp", "wdsp", "prcp"
  FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2013"
  UNION ALL
  SELECT "year", "mo", "da", "wban", "temp", "wdsp", "prcp"
  FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2014"
  UNION ALL
  SELECT "year", "mo", "da", "wban", "temp", "wdsp", "prcp"
  FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2015"
  UNION ALL
  SELECT "year", "mo", "da", "wban", "temp", "wdsp", "prcp"
  FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2016"
  UNION ALL
  SELECT "year", "mo", "da", "wban", "temp", "wdsp", "prcp"
  FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2017"
  UNION ALL
  SELECT "year", "mo", "da", "wban", "temp", "wdsp", "prcp"
  FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2018"
  UNION ALL
  SELECT "year", "mo", "da", "wban", "temp", "wdsp", "prcp"
  FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2019"
  UNION ALL
  SELECT "year", "mo", "da", "wban", "temp", "wdsp", "prcp"
  FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2020"
) AS combined_data
WHERE "wban" = '14732' AND "mo" = 6 AND "da" = 12
ORDER BY "year" ASC;