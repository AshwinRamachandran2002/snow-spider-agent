SELECT "date", "latitude", "longitude", "average_wind_speed"
FROM (
    SELECT
        DATE_FROM_PARTS("year", "month", "day") AS "date",
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
        -- Add other ICOADS_CORE tables from 2005 to 2015 if available
    ) AS combined_data
    WHERE "year" BETWEEN 2005 AND 2015
      AND "wind_speed" IS NOT NULL
      AND "month" IS NOT NULL
      AND "day" IS NOT NULL
    GROUP BY
        DATE_FROM_PARTS("year", "month", "day"),
        "latitude",
        "longitude"
) AS avg_data
ORDER BY
    "average_wind_speed" DESC NULLS LAST,
    "date" ASC,
    "latitude" ASC,
    "longitude" ASC
LIMIT 5;