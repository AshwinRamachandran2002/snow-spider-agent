/*  Count how many of the top-100 highest-damage storms (last 15 yrs)  
    fell in the single calendar month that contains the most such events. */
WITH top_events AS (
    /* bring together the last-15-year severe-storm records */
    SELECT
        "event_id",
        TO_TIMESTAMP_LTZ("event_begin_time" / 1000000) AS "event_ts",
        "damage_property",
        ROW_NUMBER() OVER (ORDER BY "damage_property" DESC) AS rn
    FROM (
        SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2009 UNION ALL
        SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2010 UNION ALL
        SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2011 UNION ALL
        SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2012 UNION ALL
        SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2013 UNION ALL
        SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2014 UNION ALL
        SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2015 UNION ALL
        SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2016 UNION ALL
        SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2017 UNION ALL
        SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2018 UNION ALL
        SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2019 UNION ALL
        SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2020 UNION ALL
        SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2021 UNION ALL
        SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2022 UNION ALL
        SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2023 UNION ALL
        SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2024
    )
    WHERE "damage_property" IS NOT NULL
    QUALIFY rn <= 100                      -- keep only the top-100 by damage
),
month_counts AS (
    SELECT
        EXTRACT(MONTH FROM "event_ts") AS event_month,
        COUNT(*)                         AS event_count
    FROM top_events
    GROUP BY event_month
    ORDER BY event_count DESC, event_month
    LIMIT 1                              -- the single most-affected month
)
SELECT event_count AS total_events_in_most_affected_month
FROM month_counts;