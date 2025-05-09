WITH union_data AS (

    SELECT "year",
           "month",
           "day",
           "latitude",
           "longitude",
           "wind_speed"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2005

    UNION ALL
    SELECT "year","month","day","latitude","longitude","wind_speed"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2006

    UNION ALL
    SELECT "year","month","day","latitude","longitude","wind_speed"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2007

    UNION ALL
    SELECT "year","month","day","latitude","longitude","wind_speed"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2008

    UNION ALL
    SELECT "year","month","day","latitude","longitude","wind_speed"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2009

    UNION ALL
    SELECT "year","month","day","latitude","longitude","wind_speed"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2010

    UNION ALL
    SELECT "year","month","day","latitude","longitude","wind_speed"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2011

    UNION ALL
    SELECT "year","month","day","latitude","longitude","wind_speed"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2012

    UNION ALL
    SELECT "year","month","day","latitude","longitude","wind_speed"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2013

    UNION ALL
    SELECT "year","month","day","latitude","longitude","wind_speed"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2014

    UNION ALL
    SELECT "year","month","day","latitude","longitude","wind_speed"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2015
),

daily_avg AS (
    SELECT
        "latitude",
        "longitude",
        DATE_FROM_PARTS("year","month","day")      AS "date",
        AVG("wind_speed")                          AS "avg_wind_speed"
    FROM union_data
    WHERE "wind_speed" IS NOT NULL
      AND "year" BETWEEN 2005 AND 2015
    GROUP BY "latitude","longitude","year","month","day"
)

SELECT
    "latitude",
    "longitude",
    "date",
    "avg_wind_speed"
FROM daily_avg
ORDER BY "avg_wind_speed" DESC NULLS LAST
LIMIT 5;