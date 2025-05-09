SELECT
  TO_DATE(
    TO_VARCHAR("year") || '-' || LPAD(TO_VARCHAR("month"), 2, '0') || '-' || LPAD(TO_VARCHAR("day"), 2, '0'),
    'YYYY-MM-DD'
  ) AS "date",
  "latitude",
  "longitude",
  ROUND(AVG("wind_speed"), 4) AS "average_wind_speed"
FROM (
  SELECT "year", "month", "day", "latitude", "longitude", "wind_speed" FROM "NOAA_DATA"."NOAA_ICOADS"."ICOADS_CORE_2005"
  UNION ALL
  SELECT "year", "month", "day", "latitude", "longitude", "wind_speed" FROM "NOAA_DATA"."NOAA_ICOADS"."ICOADS_CORE_2006"
  UNION ALL
  SELECT "year", "month", "day", "latitude", "longitude", "wind_speed" FROM "NOAA_DATA"."NOAA_ICOADS"."ICOADS_CORE_2007"
  UNION ALL
  SELECT "year", "month", "day", "latitude", "longitude", "wind_speed" FROM "NOAA_DATA"."NOAA_ICOADS"."ICOADS_CORE_2008"
  UNION ALL
  SELECT "year", "month", "day", "latitude", "longitude", "wind_speed" FROM "NOAA_DATA"."NOAA_ICOADS"."ICOADS_CORE_2009"
  UNION ALL
  SELECT "year", "month", "day", "latitude", "longitude", "wind_speed" FROM "NOAA_DATA"."NOAA_ICOADS"."ICOADS_CORE_2010"
  UNION ALL
  SELECT "year", "month", "day", "latitude", "longitude", "wind_speed" FROM "NOAA_DATA"."NOAA_ICOADS"."ICOADS_CORE_2011"
  UNION ALL
  SELECT "year", "month", "day", "latitude", "longitude", "wind_speed" FROM "NOAA_DATA"."NOAA_ICOADS"."ICOADS_CORE_2012"
  UNION ALL
  SELECT "year", "month", "day", "latitude", "longitude", "wind_speed" FROM "NOAA_DATA"."NOAA_ICOADS"."ICOADS_CORE_2013"
  UNION ALL
  SELECT "year", "month", "day", "latitude", "longitude", "wind_speed" FROM "NOAA_DATA"."NOAA_ICOADS"."ICOADS_CORE_2014"
  UNION ALL
  SELECT "year", "month", "day", "latitude", "longitude", "wind_speed" FROM "NOAA_DATA"."NOAA_ICOADS"."ICOADS_CORE_2015"
) AS "AllData"
WHERE "wind_speed" IS NOT NULL AND "year" BETWEEN 2005 AND 2015
GROUP BY "year", "month", "day", "latitude", "longitude"
ORDER BY "average_wind_speed" DESC NULLS LAST, "year" DESC, "month" DESC, "day" DESC
LIMIT 5;