-- Task: Find the top 3 months between 2010 and 2014 with the smallest total of absolute differences between the averages of air temperature, wet bulb temperature, dew point temperature, and sea surface temperature. For each month in this period, calculate the average values of these four temperature variables, compute the absolute differences between each pair of these averages (a total of six pairs), sum these differences, round the sum to four decimal places, and present the respective numerical year, month, and the calculated sum of differences in the result.
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
        SELECT "year", "month", "air_temperature", "wetbulb_temperature", "dewpoint_temperature", "sea_surface_temp"
        FROM "NOAA_DATA"."NOAA_ICOADS"."ICOADS_CORE_2010"
        UNION ALL
        SELECT "year", "month", "air_temperature", "wetbulb_temperature", "dewpoint_temperature", "sea_surface_temp"
        FROM "NOAA_DATA"."NOAA_ICOADS"."ICOADS_CORE_2011"
        UNION ALL
        SELECT "year", "month", "air_temperature", "wetbulb_temperature", "dewpoint_temperature", "sea_surface_temp"
        FROM "NOAA_DATA"."NOAA_ICOADS"."ICOADS_CORE_2012"
        UNION ALL
        SELECT "year", "month", "air_temperature", "wetbulb_temperature", "dewpoint_temperature", "sea_surface_temp"
        FROM "NOAA_DATA"."NOAA_ICOADS"."ICOADS_CORE_2013"
        UNION ALL
        SELECT "year", "month", "air_temperature", "wetbulb_temperature", "dewpoint_temperature", "sea_surface_temp"
        FROM "NOAA_DATA"."NOAA_ICOADS"."ICOADS_CORE_2014"
    ) AS combined
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