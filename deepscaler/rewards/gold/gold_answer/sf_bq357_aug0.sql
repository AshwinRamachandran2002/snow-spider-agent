-- Task: Retrieve the combinations of latitude, longitude, and dates between 2005 and 2015 that have the top 5 highest daily average wind speeds. The average wind speed is calculated per day and per location, excluding records with missing wind speed values. Use data from the tables "ICOADS_CORE_2005" to "ICOADS_CORE_2015".
SELECT
  DATE_FROM_PARTS(t."year", t."month", t."day") AS "date",
  t."latitude",
  t."longitude",
  ROUND(AVG(TRY_TO_DOUBLE(t."wind_speed")), 4) AS "average_wind_speed"
FROM
  (
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
  ) t
WHERE
  TRY_TO_DOUBLE(t."wind_speed") IS NOT NULL
  AND t."year" BETWEEN 2005 AND 2015
GROUP BY
  DATE_FROM_PARTS(t."year", t."month", t."day"), t."latitude", t."longitude"
ORDER BY
  "average_wind_speed" DESC NULLS LAST
LIMIT 5;