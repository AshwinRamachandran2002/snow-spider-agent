WITH all_events AS (
    /*  gather the past-15-year severe-storm events (2010-2024)  */
    SELECT "damage_property"        AS dmg ,
           TO_TIMESTAMP_LTZ("event_begin_time"/1000000)  AS evt_ts
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2010
    UNION ALL
    SELECT "damage_property", TO_TIMESTAMP_LTZ("event_begin_time"/1000000)
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2011
    UNION ALL
    SELECT "damage_property", TO_TIMESTAMP_LTZ("event_begin_time"/1000000)
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2012
    UNION ALL
    SELECT "damage_property", TO_TIMESTAMP_LTZ("event_begin_time"/1000000)
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2013
    UNION ALL
    SELECT "damage_property", TO_TIMESTAMP_LTZ("event_begin_time"/1000000)
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2014
    UNION ALL
    SELECT "damage_property", TO_TIMESTAMP_LTZ("event_begin_time"/1000000)
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2015
    UNION ALL
    SELECT "damage_property", TO_TIMESTAMP_LTZ("event_begin_time"/1000000)
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2016
    UNION ALL
    SELECT "damage_property", TO_TIMESTAMP_LTZ("event_begin_time"/1000000)
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2017
    UNION ALL
    SELECT "damage_property", TO_TIMESTAMP_LTZ("event_begin_time"/1000000)
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2018
    UNION ALL
    SELECT "damage_property", TO_TIMESTAMP_LTZ("event_begin_time"/1000000)
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2019
    UNION ALL
    SELECT "damage_property", TO_TIMESTAMP_LTZ("event_begin_time"/1000000)
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2020
    UNION ALL
    SELECT "damage_property", TO_TIMESTAMP_LTZ("event_begin_time"/1000000)
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2021
    UNION ALL
    SELECT "damage_property", TO_TIMESTAMP_LTZ("event_begin_time"/1000000)
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2022
    UNION ALL
    SELECT "damage_property", TO_TIMESTAMP_LTZ("event_begin_time"/1000000)
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2023
    UNION ALL
    SELECT "damage_property", TO_TIMESTAMP_LTZ("event_begin_time"/1000000)
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2024
),
top_100 AS (          --  highest property-damage events
    SELECT *
    FROM all_events
    WHERE dmg IS NOT NULL AND dmg > 0
    ORDER BY dmg DESC NULLS LAST
    LIMIT 100
),
month_counts AS (     --  count events per month within those 100
    SELECT DATE_PART('month', evt_ts) AS storm_month ,
           COUNT(*)                   AS event_cnt
    FROM   top_100
    GROUP  BY storm_month
)
SELECT event_cnt  AS total_events_in_most_affected_month
FROM   month_counts
ORDER  BY event_cnt DESC NULLS LAST
LIMIT  1;