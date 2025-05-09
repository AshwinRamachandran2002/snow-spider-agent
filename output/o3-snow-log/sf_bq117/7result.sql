WITH all_events AS (
    SELECT "event_begin_time" AS ts ,
           "damage_property"    AS damage
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2010
    UNION ALL
    SELECT "event_begin_time", "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2011
    UNION ALL
    SELECT "event_begin_time", "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2012
    UNION ALL
    SELECT "event_begin_time", "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2013
    UNION ALL
    SELECT "event_begin_time", "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2014
    UNION ALL
    SELECT "event_begin_time", "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2015
    UNION ALL
    SELECT "event_begin_time", "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2016
    UNION ALL
    SELECT "event_begin_time", "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2017
    UNION ALL
    SELECT "event_begin_time", "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2018
    UNION ALL
    SELECT "event_begin_time", "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2019
    UNION ALL
    SELECT "event_begin_time", "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2020
    UNION ALL
    SELECT "event_begin_time", "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2021
    UNION ALL
    SELECT "event_begin_time", "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2022
    UNION ALL
    SELECT "event_begin_time", "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2023
    UNION ALL
    SELECT "event_begin_time", "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2024
),
top_damage AS (
    SELECT 
        ts,
        damage,
        EXTRACT(MONTH FROM TO_TIMESTAMP_LTZ(ts/1000000)) AS month_num
    FROM all_events
    WHERE damage IS NOT NULL
    ORDER BY damage DESC NULLS LAST
    LIMIT 100
),
month_counts AS (
    SELECT 
        month_num,
        COUNT(*) AS event_count
    FROM top_damage
    GROUP BY month_num
    ORDER BY event_count DESC
    LIMIT 1
)
SELECT event_count AS "TOTAL_EVENTS_IN_MOST_AFFECTED_MONTH"
FROM month_counts;