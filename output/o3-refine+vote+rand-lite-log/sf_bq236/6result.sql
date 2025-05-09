WITH hail_events AS (

    ----------------------------------------------------------------
    --  Consolidate hail events (latitude & longitude only) 
    --  from each yearly “STORMS_20XX” table for the last 10 years
    ----------------------------------------------------------------
    
    SELECT  "event_latitude"  AS lat ,
            "event_longitude" AS lon
    FROM    NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2014"
    WHERE   "event_type" = 'hail'
            AND "event_latitude"  IS NOT NULL
            AND "event_longitude" IS NOT NULL
    
    UNION ALL
    SELECT  "event_latitude", "event_longitude"
    FROM    NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2015"
    WHERE   "event_type" = 'hail'
            AND "event_latitude"  IS NOT NULL
            AND "event_longitude" IS NOT NULL
    
    UNION ALL
    SELECT  "event_latitude", "event_longitude"
    FROM    NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2016"
    WHERE   "event_type" = 'hail'
            AND "event_latitude"  IS NOT NULL
            AND "event_longitude" IS NOT NULL
    
    UNION ALL
    SELECT  "event_latitude", "event_longitude"
    FROM    NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2017"
    WHERE   "event_type" = 'hail'
            AND "event_latitude"  IS NOT NULL
            AND "event_longitude" IS NOT NULL
    
    UNION ALL
    SELECT  "event_latitude", "event_longitude"
    FROM    NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2018"
    WHERE   "event_type" = 'hail'
            AND "event_latitude"  IS NOT NULL
            AND "event_longitude" IS NOT NULL
    
    UNION ALL
    SELECT  "event_latitude", "event_longitude"
    FROM    NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2019"
    WHERE   "event_type" = 'hail'
            AND "event_latitude"  IS NOT NULL
            AND "event_longitude" IS NOT NULL
    
    UNION ALL
    SELECT  "event_latitude", "event_longitude"
    FROM    NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2020"
    WHERE   "event_type" = 'hail'
            AND "event_latitude"  IS NOT NULL
            AND "event_longitude" IS NOT NULL
    
    UNION ALL
    SELECT  "event_latitude", "event_longitude"
    FROM    NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2021"
    WHERE   "event_type" = 'hail'
            AND "event_latitude"  IS NOT NULL
            AND "event_longitude" IS NOT NULL
    
    UNION ALL
    SELECT  "event_latitude", "event_longitude"
    FROM    NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2022"
    WHERE   "event_type" = 'hail'
            AND "event_latitude"  IS NOT NULL
            AND "event_longitude" IS NOT NULL
    
    UNION ALL
    SELECT  "event_latitude", "event_longitude"
    FROM    NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2023"
    WHERE   "event_type" = 'hail'
            AND "event_latitude"  IS NOT NULL
            AND "event_longitude" IS NOT NULL
)

--------------------------------------------------------------------
--  Join each hail event point to the ZIP code polygon it falls in
--------------------------------------------------------------------
SELECT
    z."zip_code"                                     AS zip_code ,
    COUNT(*)                                         AS hail_event_count
FROM hail_events  e
JOIN NOAA_DATA_PLUS.GEO_US_BOUNDARIES."ZIP_CODES" z
      ON ST_WITHIN(
            ST_POINT(e.lon , e.lat)               ,     -- GEOGRAPHY point
            TO_GEOGRAPHY(z."zip_code_geom")             -- ZIP polygon
         )
GROUP BY z."zip_code"
ORDER BY hail_event_count DESC NULLS LAST ,
         z."zip_code"
LIMIT 5;