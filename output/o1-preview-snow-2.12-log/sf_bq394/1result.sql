SELECT
  "year",
  "month",
  ROUND(
    ABS(AVG("air_temperature") - AVG("wetbulb_temperature")) +
    ABS(AVG("air_temperature") - AVG("dewpoint_temperature")) +
    ABS(AVG("air_temperature") - AVG("sea_surface_temp")) +
    ABS(AVG("wetbulb_temperature") - AVG("dewpoint_temperature")) +
    ABS(AVG("wetbulb_temperature") - AVG("sea_surface_temp")) +
    ABS(AVG("dewpoint_temperature") - AVG("sea_surface_temp")),
    4
  ) AS "Sum_of_Differences"
FROM
  (
    SELECT * FROM "NOAA_DATA"."NOAA_ICOADS"."ICOADS_CORE_2010"
    UNION ALL
    SELECT * FROM "NOAA_DATA"."NOAA_ICOADS"."ICOADS_CORE_2011"
    UNION ALL
    SELECT * FROM "NOAA_DATA"."NOAA_ICOADS"."ICOADS_CORE_2012"
    UNION ALL
    SELECT * FROM "NOAA_DATA"."NOAA_ICOADS"."ICOADS_CORE_2013"
    UNION ALL
    SELECT * FROM "NOAA_DATA"."NOAA_ICOADS"."ICOADS_CORE_2014"
  ) AS combined_data
WHERE
  "year" BETWEEN 2010 AND 2014
  AND "air_temperature" IS NOT NULL
  AND "wetbulb_temperature" IS NOT NULL
  AND "dewpoint_temperature" IS NOT NULL
  AND "sea_surface_temp" IS NOT NULL
GROUP BY
  "year",
  "month"
ORDER BY
  "Sum_of_Differences" ASC
LIMIT 3;