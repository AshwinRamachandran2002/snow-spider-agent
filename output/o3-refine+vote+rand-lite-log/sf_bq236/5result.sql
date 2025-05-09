WITH hail_events AS (

    /* Gather all hail events from the last 10 calendar years (2014‑2023) */
    SELECT
        ST_MAKEPOINT("event_longitude","event_latitude") AS pt,
        TO_TIMESTAMP("event_begin_time" / 1000000)       AS evt_ts
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2014
    WHERE LOWER("event_type") = 'hail'

    UNION ALL
    SELECT ST_MAKEPOINT("event_longitude","event_latitude"), TO_TIMESTAMP("event_begin_time" / 1000000)
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2015
    WHERE LOWER("event_type") = 'hail'

    UNION ALL
    SELECT ST_MAKEPOINT("event_longitude","event_latitude"), TO_TIMESTAMP("event_begin_time" / 1000000)
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2016
    WHERE LOWER("event_type") = 'hail'

    UNION ALL
    SELECT ST_MAKEPOINT("event_longitude","event_latitude"), TO_TIMESTAMP("event_begin_time" / 1000000)
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2017
    WHERE LOWER("event_type") = 'hail'

    UNION ALL
    SELECT ST_MAKEPOINT("event_longitude","event_latitude"), TO_TIMESTAMP("event_begin_time" / 1000000)
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2018
    WHERE LOWER("event_type") = 'hail'

    UNION ALL
    SELECT ST_MAKEPOINT("event_longitude","event_latitude"), TO_TIMESTAMP("event_begin_time" / 1000000)
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2019
    WHERE LOWER("event_type") = 'hail'

    UNION ALL
    SELECT ST_MAKEPOINT("event_longitude","event_latitude"), TO_TIMESTAMP("event_begin_time" / 1000000)
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2020
    WHERE LOWER("event_type") = 'hail'

    UNION ALL
    SELECT ST_MAKEPOINT("event_longitude","event_latitude"), TO_TIMESTAMP("event_begin_time" / 1000000)
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2021
    WHERE LOWER("event_type") = 'hail'

    UNION ALL
    SELECT ST_MAKEPOINT("event_longitude","event_latitude"), TO_TIMESTAMP("event_begin_time" / 1000000)
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2022
    WHERE LOWER("event_type") = 'hail'

    UNION ALL
    SELECT ST_MAKEPOINT("event_longitude","event_latitude"), TO_TIMESTAMP("event_begin_time" / 1000000)
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2023
    WHERE LOWER("event_type") = 'hail'

),

recent_hail AS (
    SELECT pt
    FROM hail_events
    WHERE evt_ts >= DATEADD(year,-10,CURRENT_DATE)
)

SELECT
    z."zip_code",
    COUNT(*) AS hail_event_count
FROM recent_hail h
JOIN NOAA_DATA_PLUS.GEO_US_BOUNDARIES.ZIP_CODES z
  ON ST_WITHIN(
        h.pt,
        TO_GEOGRAPHY(z."zip_code_geom")
     )
GROUP BY z."zip_code"
ORDER BY hail_event_count DESC NULLS LAST,
         z."zip_code"
LIMIT 5;