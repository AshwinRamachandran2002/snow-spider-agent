WITH hail_reports AS (

    /* --------------------------------------------------------------
       Build one GEOGRAPHY point for every hail‑storm record
       (past 10 calendar years: 2014‑2024)
       -------------------------------------------------------------- */
    SELECT ST_POINT("event_longitude", "event_latitude") AS hail_point
      FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2014
     WHERE UPPER("event_type") = 'HAIL'
       AND "event_longitude" IS NOT NULL
       AND "event_latitude"  IS NOT NULL

 UNION ALL
    SELECT ST_POINT("event_longitude", "event_latitude")
      FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2015
     WHERE UPPER("event_type") = 'HAIL'
       AND "event_longitude" IS NOT NULL
       AND "event_latitude"  IS NOT NULL

 UNION ALL
    SELECT ST_POINT("event_longitude", "event_latitude")
      FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2016
     WHERE UPPER("event_type") = 'HAIL'
       AND "event_longitude" IS NOT NULL
       AND "event_latitude"  IS NOT NULL

 UNION ALL
    SELECT ST_POINT("event_longitude", "event_latitude")
      FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2017
     WHERE UPPER("event_type") = 'HAIL'
       AND "event_longitude" IS NOT NULL
       AND "event_latitude"  IS NOT NULL

 UNION ALL
    SELECT ST_POINT("event_longitude", "event_latitude")
      FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2018
     WHERE UPPER("event_type") = 'HAIL'
       AND "event_longitude" IS NOT NULL
       AND "event_latitude"  IS NOT NULL

 UNION ALL
    SELECT ST_POINT("event_longitude", "event_latitude")
      FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2019
     WHERE UPPER("event_type") = 'HAIL'
       AND "event_longitude" IS NOT NULL
       AND "event_latitude"  IS NOT NULL

 UNION ALL
    SELECT ST_POINT("event_longitude", "event_latitude")
      FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2020
     WHERE UPPER("event_type") = 'HAIL'
       AND "event_longitude" IS NOT NULL
       AND "event_latitude"  IS NOT NULL

 UNION ALL
    SELECT ST_POINT("event_longitude", "event_latitude")
      FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2021
     WHERE UPPER("event_type") = 'HAIL'
       AND "event_longitude" IS NOT NULL
       AND "event_latitude"  IS NOT NULL

 UNION ALL
    SELECT ST_POINT("event_longitude", "event_latitude")
      FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2022
     WHERE UPPER("event_type") = 'HAIL'
       AND "event_longitude" IS NOT NULL
       AND "event_latitude"  IS NOT NULL

 UNION ALL
    SELECT ST_POINT("event_longitude", "event_latitude")
      FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2023
     WHERE UPPER("event_type") = 'HAIL'
       AND "event_longitude" IS NOT NULL
       AND "event_latitude"  IS NOT NULL

 UNION ALL
    SELECT ST_POINT("event_longitude", "event_latitude")
      FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2024
     WHERE UPPER("event_type") = 'HAIL'
       AND "event_longitude" IS NOT NULL
       AND "event_latitude"  IS NOT NULL
)

SELECT
    z."zip_code"                               AS zip_code,
    COUNT(*)                                   AS hail_event_count
FROM hail_reports h
JOIN NOAA_DATA_PLUS.GEO_US_BOUNDARIES.ZIP_CODES z
  ON ST_WITHIN(
         h.hail_point,
         TO_GEOGRAPHY(z."zip_code_geom")
     )
GROUP BY z."zip_code"
ORDER BY hail_event_count DESC NULLS LAST,
         zip_code
FETCH FIRST 5 ROWS ONLY;