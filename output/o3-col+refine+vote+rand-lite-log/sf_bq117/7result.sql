WITH union_storms AS (
    SELECT "event_id",
           "event_begin_time",
           "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2010
    UNION ALL
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2011
    UNION ALL
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2012
    UNION ALL
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2013
    UNION ALL
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2014
    UNION ALL
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2015
    UNION ALL
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2016
    UNION ALL
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2017
    UNION ALL
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2018
    UNION ALL
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2019
    UNION ALL
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2020
    UNION ALL
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2021
    UNION ALL
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2022
    UNION ALL
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2023
    UNION ALL
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2024
),
top100 AS (
    SELECT "event_begin_time"
    FROM union_storms
    WHERE "damage_property" IS NOT NULL
    ORDER BY "damage_property" DESC NULLS LAST
    LIMIT 100
),
month_counts AS (
    SELECT TO_CHAR(TO_TIMESTAMP_LTZ("event_begin_time" / 1000000), 'YYYY-MM') AS "event_month",
           COUNT(*) AS "events_in_month"
    FROM top100
    GROUP BY "event_month"
)
SELECT MAX("events_in_month") AS "total_events_in_most_affected_month"
FROM month_counts;