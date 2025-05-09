WITH all_observations AS (

    /* 2005 */
    SELECT 
        "latitude"                    AS lat,
        "longitude"                   AS lon,
        "wind_speed"                  AS wnd,
        TO_DATE( TO_CHAR("year")||'-'||LPAD("month",2,'0')||'-'||LPAD("day",2,'0') )  AS obs_date
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2005

    UNION ALL
    /* 2006 */
    SELECT 
        "latitude", "longitude", "wind_speed",
        TO_DATE( TO_CHAR("year")||'-'||LPAD("month",2,'0')||'-'||LPAD("day",2,'0') )
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2006

    UNION ALL
    /* 2007 */
    SELECT 
        "latitude", "longitude", "wind_speed",
        TO_DATE( TO_CHAR("year")||'-'||LPAD("month",2,'0')||'-'||LPAD("day",2,'0') )
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2007

    UNION ALL
    /* 2008 */
    SELECT 
        "latitude", "longitude", "wind_speed",
        TO_DATE( TO_CHAR("year")||'-'||LPAD("month",2,'0')||'-'||LPAD("day",2,'0') )
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2008

    UNION ALL
    /* 2009 */
    SELECT 
        "latitude", "longitude", "wind_speed",
        TO_DATE( TO_CHAR("year")||'-'||LPAD("month",2,'0')||'-'||LPAD("day",2,'0') )
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2009

    UNION ALL
    /* 2010 */
    SELECT 
        "latitude", "longitude", "wind_speed",
        TO_DATE( TO_CHAR("year")||'-'||LPAD("month",2,'0')||'-'||LPAD("day",2,'0') )
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2010

    UNION ALL
    /* 2011 */
    SELECT 
        "latitude", "longitude", "wind_speed",
        TO_DATE( TO_CHAR("year")||'-'||LPAD("month",2,'0')||'-'||LPAD("day",2,'0') )
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2011

    UNION ALL
    /* 2012 */
    SELECT 
        "latitude", "longitude", "wind_speed",
        TO_DATE( TO_CHAR("year")||'-'||LPAD("month",2,'0')||'-'||LPAD("day",2,'0') )
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2012

    UNION ALL
    /* 2013 */
    SELECT 
        "latitude", "longitude", "wind_speed",
        TO_DATE( TO_CHAR("year")||'-'||LPAD("month",2,'0')||'-'||LPAD("day",2,'0') )
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2013

    UNION ALL
    /* 2014 */
    SELECT 
        "latitude", "longitude", "wind_speed",
        TO_DATE( TO_CHAR("year")||'-'||LPAD("month",2,'0')||'-'||LPAD("day",2,'0') )
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2014

    UNION ALL
    /* 2015 */
    SELECT 
        "latitude", "longitude", "wind_speed",
        TO_DATE( TO_CHAR("year")||'-'||LPAD("month",2,'0')||'-'||LPAD("day",2,'0') )
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2015
),

daily_avg AS (
    SELECT
        obs_date,
        lat,
        lon,
        AVG(wnd) AS avg_wind_speed
    FROM all_observations
    WHERE wnd IS NOT NULL                             -- exclude missing wind-speed values
      AND obs_date BETWEEN '2005-01-01' AND '2015-12-31'
    GROUP BY obs_date, lat, lon
)

SELECT
    lat        AS "latitude",
    lon        AS "longitude",
    obs_date   AS "date",
    avg_wind_speed
FROM daily_avg
ORDER BY avg_wind_speed DESC NULLS LAST
LIMIT 5;