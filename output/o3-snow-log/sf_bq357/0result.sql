-- Top 5 daily-average surface-wind speeds (2005-2015) from ICOADS core data
SELECT
    "latitude",
    "longitude",
    DATE_FROM_PARTS("year","month","day")         AS "date",
    AVG("wind_speed")                             AS "avg_wind_speed"
FROM (
        SELECT "latitude","longitude","year","month","day","wind_speed" FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2005
 UNION ALL SELECT "latitude","longitude","year","month","day","wind_speed" FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2006
 UNION ALL SELECT "latitude","longitude","year","month","day","wind_speed" FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2007
 UNION ALL SELECT "latitude","longitude","year","month","day","wind_speed" FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2008
 UNION ALL SELECT "latitude","longitude","year","month","day","wind_speed" FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2009
 UNION ALL SELECT "latitude","longitude","year","month","day","wind_speed" FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2010
 UNION ALL SELECT "latitude","longitude","year","month","day","wind_speed" FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2011
 UNION ALL SELECT "latitude","longitude","year","month","day","wind_speed" FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2012
 UNION ALL SELECT "latitude","longitude","year","month","day","wind_speed" FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2013
 UNION ALL SELECT "latitude","longitude","year","month","day","wind_speed" FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2014
 UNION ALL SELECT "latitude","longitude","year","month","day","wind_speed" FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2015
) AS icoads
WHERE "wind_speed" IS NOT NULL                     -- exclude missing values
GROUP BY
    "latitude",
    "longitude",
    "year",
    "month",
    "day"
ORDER BY
    "avg_wind_speed" DESC NULLS LAST
LIMIT 5;