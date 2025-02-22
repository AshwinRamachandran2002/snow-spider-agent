-- Task: What are the top 3 months between 2010 and 2014 with the smallest absolute difference between the average air temperature and the average wet bulb temperature? Include the respective years, months, and the absolute difference.

SELECT
    "year",
    "month",
    ROUND(
        ABS(AVG("air_temperature") - AVG("wetbulb_temperature")),
        4
    ) AS "Difference"
FROM
    (
        SELECT "year", "month", "air_temperature", "wetbulb_temperature"
        FROM "NOAA_DATA"."NOAA_ICOADS"."ICOADS_CORE_2010"
        UNION ALL
        SELECT "year", "month", "air_temperature", "wetbulb_temperature"
        FROM "NOAA_DATA"."NOAA_ICOADS"."ICOADS_CORE_2011"
        UNION ALL
        SELECT "year", "month", "air_temperature", "wetbulb_temperature"
        FROM "NOAA_DATA"."NOAA_ICOADS"."ICOADS_CORE_2012"
        UNION ALL
        SELECT "year", "month", "air_temperature", "wetbulb_temperature"
        FROM "NOAA_DATA"."NOAA_ICOADS"."ICOADS_CORE_2013"
        UNION ALL
        SELECT "year", "month", "air_temperature", "wetbulb_temperature"
        FROM "NOAA_DATA"."NOAA_ICOADS"."ICOADS_CORE_2014"
    ) AS combined
WHERE
    "year" BETWEEN 2010 AND 2014
    AND "air_temperature" IS NOT NULL
    AND "wetbulb_temperature" IS NOT NULL
GROUP BY
    "year",
    "month"
ORDER BY
    "Difference" ASC
LIMIT 3;