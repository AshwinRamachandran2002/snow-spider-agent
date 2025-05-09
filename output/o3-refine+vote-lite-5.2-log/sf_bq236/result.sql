WITH hail_events AS (

    /* ---------------- 2014 ---------------- */
    SELECT 
        "event_latitude"  AS lat,
        "event_longitude" AS lon
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2014
    WHERE LOWER("event_type") = 'hail'

    UNION ALL
    /* ---------------- 2015 ---------------- */
    SELECT "event_latitude", "event_longitude"
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2015
    WHERE LOWER("event_type") = 'hail'

    UNION ALL
    /* ---------------- 2016 ---------------- */
    SELECT "event_latitude", "event_longitude"
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2016
    WHERE LOWER("event_type") = 'hail'

    UNION ALL
    /* ---------------- 2017 ---------------- */
    SELECT "event_latitude", "event_longitude"
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2017
    WHERE LOWER("event_type") = 'hail'

    UNION ALL
    /* ---------------- 2018 ---------------- */
    SELECT "event_latitude", "event_longitude"
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2018
    WHERE LOWER("event_type") = 'hail'

    UNION ALL
    /* ---------------- 2019 ---------------- */
    SELECT "event_latitude", "event_longitude"
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2019
    WHERE LOWER("event_type") = 'hail'

    UNION ALL
    /* ---------------- 2020 ---------------- */
    SELECT "event_latitude", "event_longitude"
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2020
    WHERE LOWER("event_type") = 'hail'

    UNION ALL
    /* ---------------- 2021 ---------------- */
    SELECT "event_latitude", "event_longitude"
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2021
    WHERE LOWER("event_type") = 'hail'

    UNION ALL
    /* ---------------- 2022 ---------------- */
    SELECT "event_latitude", "event_longitude"
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2022
    WHERE LOWER("event_type") = 'hail'

    UNION ALL
    /* ---------------- 2023 ---------------- */
    SELECT "event_latitude", "event_longitude"
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2023
    WHERE LOWER("event_type") = 'hail'

    UNION ALL
    /* ---------------- 2024 ---------------- */
    SELECT "event_latitude", "event_longitude"
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2024
    WHERE LOWER("event_type") = 'hail'

),

/* Filter out events where coordinates are missing */
valid_events AS (
    SELECT 
        lat,
        lon,
        TO_GEOGRAPHY('POINT(' || lon || ' ' || lat || ')') AS event_point
    FROM hail_events
    WHERE lat IS NOT NULL 
      AND lon IS NOT NULL
),

/* Spatial match of hail events to ZIP‑code polygons */
events_by_zip AS (
    SELECT 
        z."zip_code",
        COUNT(*) AS hail_cnt
    FROM valid_events   e
    JOIN NOAA_DATA_PLUS.GEO_US_BOUNDARIES.ZIP_CODES z
      ON ST_WITHIN(
           e.event_point,
           TO_GEOGRAPHY(z."zip_code_geom")
         )
    GROUP BY z."zip_code"
)

/* Top‑5 ZIP codes with most hail events */
SELECT 
    "zip_code",
    hail_cnt AS hail_events_last_10yrs
FROM events_by_zip
ORDER BY hail_cnt DESC NULLS LAST, "zip_code"
LIMIT 5;