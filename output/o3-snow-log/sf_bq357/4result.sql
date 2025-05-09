WITH union_data AS (
    /*  Gather all observations that have a valid wind speed   */
    SELECT "year", "month", "day", "latitude", "longitude", "wind_speed"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2005 WHERE "wind_speed" IS NOT NULL
    UNION ALL
    SELECT "year", "month", "day", "latitude", "longitude", "wind_speed"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2006 WHERE "wind_speed" IS NOT NULL
    UNION ALL
    SELECT "year", "month", "day", "latitude", "longitude", "wind_speed"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2007 WHERE "wind_speed" IS NOT NULL
    UNION ALL
    SELECT "year", "month", "day", "latitude", "longitude", "wind_speed"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2008 WHERE "wind_speed" IS NOT NULL
    UNION ALL
    SELECT "year", "month", "day", "latitude", "longitude", "wind_speed"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2009 WHERE "wind_speed" IS NOT NULL
    UNION ALL
    SELECT "year", "month", "day", "latitude", "longitude", "wind_speed"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2010 WHERE "wind_speed" IS NOT NULL
    UNION ALL
    SELECT "year", "month", "day", "latitude", "longitude", "wind_speed"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2011 WHERE "wind_speed" IS NOT NULL
    UNION ALL
    SELECT "year", "month", "day", "latitude", "longitude", "wind_speed"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2012 WHERE "wind_speed" IS NOT NULL
    UNION ALL
    SELECT "year", "month", "day", "latitude", "longitude", "wind_speed"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2013 WHERE "wind_speed" IS NOT NULL
    UNION ALL
    SELECT "year", "month", "day", "latitude", "longitude", "wind_speed"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2014 WHERE "wind_speed" IS NOT NULL
    UNION ALL
    SELECT "year", "month", "day", "latitude", "longitude", "wind_speed"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2015 WHERE "wind_speed" IS NOT NULL
), daily_avg AS (
    /*  Compute daily average wind speed and the mean position for the day  */
    SELECT
        TO_DATE(
            LPAD("year", 4, '0') || '-' ||
            LPAD("month", 2, '0') || '-' ||
            LPAD("day",   2, '0')
        )                                              AS "date",
        AVG("wind_speed")                              AS "avg_wind_speed",
        AVG("latitude")                                AS "avg_latitude",
        AVG("longitude")                               AS "avg_longitude"
    FROM union_data
    WHERE "year" BETWEEN 2005 AND 2015
    GROUP BY 1
)
SELECT
    "avg_latitude"   AS "LATITUDE",
    "avg_longitude"  AS "LONGITUDE",
    "date"           AS "DATE"
FROM daily_avg
ORDER BY "avg_wind_speed" DESC NULLS LAST
LIMIT 5;