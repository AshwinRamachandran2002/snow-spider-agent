SELECT "year",
       AVG("temp") AS "Average_Temperature",
       AVG(TRY_TO_NUMBER("wdsp")) AS "Average_Wind_Speed",
       SUM("prcp") AS "Precipitation"
FROM (
  SELECT "stn", "year", "mo", "da", "temp", "wdsp", "prcp"
  FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2011"
  UNION ALL
  SELECT "stn", "year", "mo", "da", "temp", "wdsp", "prcp"
  FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2012"
  UNION ALL
  SELECT "stn", "year", "mo", "da", "temp", "wdsp", "prcp"
  FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2013"
  UNION ALL
  SELECT "stn", "year", "mo", "da", "temp", "wdsp", "prcp"
  FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2014"
  UNION ALL
  SELECT "stn", "year", "mo", "da", "temp", "wdsp", "prcp"
  FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2015"
  UNION ALL
  SELECT "stn", "year", "mo", "da", "temp", "wdsp", "prcp"
  FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2016"
  UNION ALL
  SELECT "stn", "year", "mo", "da", "temp", "wdsp", "prcp"
  FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2017"
  UNION ALL
  SELECT "stn", "year", "mo", "da", "temp", "wdsp", "prcp"
  FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2018"
  UNION ALL
  SELECT "stn", "year", "mo", "da", "temp", "wdsp", "prcp"
  FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2019"
  UNION ALL
  SELECT "stn", "year", "mo", "da", "temp", "wdsp", "prcp"
  FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2020"
) AS combined_data
WHERE "stn" = '725030' AND "mo" = '06' AND "da" = '12'
GROUP BY "year"
ORDER BY "year";