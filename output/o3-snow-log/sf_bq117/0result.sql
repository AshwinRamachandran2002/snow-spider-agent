WITH all_events AS (   -- 15 most–recent years of the historic-severe-storm archive
    SELECT "event_begin_time" , "damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2010
    UNION ALL SELECT "event_begin_time" , "damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2011
    UNION ALL SELECT "event_begin_time" , "damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2012
    UNION ALL SELECT "event_begin_time" , "damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2013
    UNION ALL SELECT "event_begin_time" , "damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2014
    UNION ALL SELECT "event_begin_time" , "damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2015
    UNION ALL SELECT "event_begin_time" , "damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2016
    UNION ALL SELECT "event_begin_time" , "damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2017
    UNION ALL SELECT "event_begin_time" , "damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2018
    UNION ALL SELECT "event_begin_time" , "damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2019
    UNION ALL SELECT "event_begin_time" , "damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2020
    UNION ALL SELECT "event_begin_time" , "damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2021
    UNION ALL SELECT "event_begin_time" , "damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2022
    UNION ALL SELECT "event_begin_time" , "damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2023
    UNION ALL SELECT "event_begin_time" , "damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2024
),
-- keep only records that have a property-damage value
filtered AS (
    SELECT 
        TO_TIMESTAMP_LTZ("event_begin_time" / 1000000)     AS evt_ts,   -- micro-seconds → seconds
        "damage_property"
    FROM all_events
    WHERE "damage_property" IS NOT NULL
),
-- the 100 costliest severe-storm events during the last 15 years
top_100 AS (
    SELECT *
    FROM filtered
    ORDER BY "damage_property" DESC NULLS LAST
    LIMIT 100
),
-- how many of those events occur in each calendar month?
month_counts AS (
    SELECT 
        EXTRACT(MONTH FROM evt_ts) AS month_no,
        COUNT(*)                  AS events_in_month
    FROM top_100
    GROUP BY month_no
)
-- final answer: number of events in the single most-affected month
SELECT MAX(events_in_month) AS total_events_in_most_affected_month
FROM month_counts;