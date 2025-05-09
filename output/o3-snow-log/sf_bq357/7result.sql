WITH "ICOADS_UNION" AS (
    SELECT "year","month","day","latitude","longitude","wind_speed" FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2005
    UNION ALL SELECT "year","month","day","latitude","longitude","wind_speed" FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2006
    UNION ALL SELECT "year","month","day","latitude","longitude","wind_speed" FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2007
    UNION ALL SELECT "year","month","day","latitude","longitude","wind_speed" FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2008
    UNION ALL SELECT "year","month","day","latitude","longitude","wind_speed" FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2009
    UNION ALL SELECT "year","month","day","latitude","longitude","wind_speed" FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2010
    UNION ALL SELECT "year","month","day","latitude","longitude","wind_speed" FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2011
    UNION ALL SELECT "year","month","day","latitude","longitude","wind_speed" FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2012
    UNION ALL SELECT "year","month","day","latitude","longitude","wind_speed" FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2013
    UNION ALL SELECT "year","month","day","latitude","longitude","wind_speed" FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2014
    UNION ALL SELECT "year","month","day","latitude","longitude","wind_speed" FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2015
), "FILTERED" AS (
    SELECT *
    FROM "ICOADS_UNION"
    WHERE "year" BETWEEN 2005 AND 2015
      AND "wind_speed" IS NOT NULL
)
SELECT
    DATE_FROM_PARTS("year","month","day")          AS "observation_date",
    "latitude",
    "longitude",
    AVG("wind_speed")                              AS "avg_daily_wind_speed"
FROM "FILTERED"
GROUP BY
    "year","month","day","latitude","longitude"
ORDER BY
    "avg_daily_wind_speed" DESC NULLS LAST
LIMIT 5;