WITH recent_hail AS (
    /*  hail events (event_type = 'hail') from the last 10 seasons  */
    SELECT  "event_latitude"  AS lat ,
            "event_longitude" AS lon
    FROM   (
              SELECT "event_latitude","event_longitude","event_type" FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2014
        UNION ALL SELECT "event_latitude","event_longitude","event_type" FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2015
        UNION ALL SELECT "event_latitude","event_longitude","event_type" FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2016
        UNION ALL SELECT "event_latitude","event_longitude","event_type" FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2017
        UNION ALL SELECT "event_latitude","event_longitude","event_type" FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2018
        UNION ALL SELECT "event_latitude","event_longitude","event_type" FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2019
        UNION ALL SELECT "event_latitude","event_longitude","event_type" FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2020
        UNION ALL SELECT "event_latitude","event_longitude","event_type" FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2021
        UNION ALL SELECT "event_latitude","event_longitude","event_type" FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2022
        UNION ALL SELECT "event_latitude","event_longitude","event_type" FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2023
        UNION ALL SELECT "event_latitude","event_longitude","event_type" FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2024
           )
    WHERE   "event_type" ILIKE 'hail'
        AND "event_latitude"  IS NOT NULL
        AND "event_longitude" IS NOT NULL
),
hail_by_zip AS (
    SELECT  z."zip_code",
            COUNT(*) AS hail_events
    FROM   recent_hail h
    JOIN   NOAA_DATA_PLUS.GEO_US_BOUNDARIES.ZIP_CODES z
           ON ST_WITHIN(
                TO_GEOGRAPHY( 'POINT('|| h.lon || ' ' || h.lat || ')' ),
                ST_GEOGFROMWKB( z."zip_code_geom" )
              )
    GROUP  BY z."zip_code"
)
SELECT  "zip_code",
        hail_events
FROM    hail_by_zip
ORDER BY hail_events DESC NULLS LAST,
         "zip_code"
LIMIT   5;