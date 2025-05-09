WITH icoads_union AS (   
    SELECT "latitude", "longitude", "year", "month", "day", "wind_speed"
      FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2005
    UNION ALL SELECT "latitude", "longitude", "year", "month", "day", "wind_speed"
      FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2006
    UNION ALL SELECT "latitude", "longitude", "year", "month", "day", "wind_speed"
      FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2007
    UNION ALL SELECT "latitude", "longitude", "year", "month", "day", "wind_speed"
      FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2008
    UNION ALL SELECT "latitude", "longitude", "year", "month", "day", "wind_speed"
      FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2009
    UNION ALL SELECT "latitude", "longitude", "year", "month", "day", "wind_speed"
      FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2010
    UNION ALL SELECT "latitude", "longitude", "year", "month", "day", "wind_speed"
      FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2011
    UNION ALL SELECT "latitude", "longitude", "year", "month", "day", "wind_speed"
      FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2012
    UNION ALL SELECT "latitude", "longitude", "year", "month", "day", "wind_speed"
      FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2013
    UNION ALL SELECT "latitude", "longitude", "year", "month", "day", "wind_speed"
      FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2014
    UNION ALL SELECT "latitude", "longitude", "year", "month", "day", "wind_speed"
      FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2015
),

daily_avg AS (
    SELECT
        "latitude",
        "longitude",
        /* build proper calendar date */
        TO_DATE(TO_CHAR("year",'FM0000')||'-'||
                LPAD(CAST("month" AS VARCHAR),2,'0')||'-'||
                LPAD(CAST("day"   AS VARCHAR),2,'0'))       AS "date",
        AVG("wind_speed")                                   AS "avg_wind_speed"
    FROM icoads_union
    WHERE "year" BETWEEN 2005 AND 2015              -- required time window
      AND "wind_speed" IS NOT NULL                  -- exclude missing values stored as NULL
      AND "wind_speed" = "wind_speed"               -- exclude NaN values
    GROUP BY "latitude", "longitude", "date"
)

SELECT
    "latitude",
    "longitude",
    "date",
    "avg_wind_speed"
FROM daily_avg
ORDER BY "avg_wind_speed" DESC NULLS LAST
LIMIT 5;