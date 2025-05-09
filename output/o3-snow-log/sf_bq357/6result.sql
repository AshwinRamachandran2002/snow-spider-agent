WITH all_observations AS (

    /* -----------------------------------------------------------------
       Gather every wind–speed observation for the years 2005-2015 from
       each ICOADS_CORE table.  Keep the observation date, latitude,
       longitude, and wind-speed value. 
       -----------------------------------------------------------------*/
    SELECT DATE_FROM_PARTS("year","month","day")  AS obs_date ,
           "latitude"                              AS lat ,
           "longitude"                             AS lon ,
           "wind_speed"                            AS wind_speed
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2005

    UNION ALL
    SELECT DATE_FROM_PARTS("year","month","day"), "latitude", "longitude", "wind_speed"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2006

    UNION ALL
    SELECT DATE_FROM_PARTS("year","month","day"), "latitude", "longitude", "wind_speed"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2007

    UNION ALL
    SELECT DATE_FROM_PARTS("year","month","day"), "latitude", "longitude", "wind_speed"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2008

    UNION ALL
    SELECT DATE_FROM_PARTS("year","month","day"), "latitude", "longitude", "wind_speed"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2009

    UNION ALL
    SELECT DATE_FROM_PARTS("year","month","day"), "latitude", "longitude", "wind_speed"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2010

    UNION ALL
    SELECT DATE_FROM_PARTS("year","month","day"), "latitude", "longitude", "wind_speed"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2011

    UNION ALL
    SELECT DATE_FROM_PARTS("year","month","day"), "latitude", "longitude", "wind_speed"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2012

    UNION ALL
    SELECT DATE_FROM_PARTS("year","month","day"), "latitude", "longitude", "wind_speed"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2013

    UNION ALL
    SELECT DATE_FROM_PARTS("year","month","day"), "latitude", "longitude", "wind_speed"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2014

    UNION ALL
    SELECT DATE_FROM_PARTS("year","month","day"), "latitude", "longitude", "wind_speed"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2015
),

/* ---------------------------------------------------------------------
   Compute the daily-average wind speed for every unique latitude /
   longitude pair.  Exclude observations that do not have a wind-speed
   value.
   -------------------------------------------------------------------*/
daily_averages AS (
    SELECT
        obs_date,
        lat,
        lon,
        AVG(wind_speed) AS avg_wind_speed
    FROM   all_observations
    WHERE  wind_speed IS NOT NULL
      AND  obs_date BETWEEN '2005-01-01' AND '2015-12-31'
    GROUP  BY obs_date, lat, lon
)

/* ---------------------------------------------------------------------
   Return the five largest daily averages (highest winds), along with
   the associated date and coordinates.
   -------------------------------------------------------------------*/
SELECT
    obs_date               AS "DATE",
    lat                    AS "LATITUDE",
    lon                    AS "LONGITUDE",
    avg_wind_speed         AS "DAILY_AVG_WIND_SPEED"
FROM   daily_averages
ORDER  BY avg_wind_speed DESC NULLS LAST
LIMIT  5;