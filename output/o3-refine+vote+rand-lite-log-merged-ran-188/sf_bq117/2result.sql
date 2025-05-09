WITH union_storms AS (    
    SELECT TO_TIMESTAMP_LTZ("event_begin_time" / 1000000) AS evt_ts,
           "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2010
    UNION ALL
    SELECT TO_TIMESTAMP_LTZ("event_begin_time" / 1000000), "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2011
    UNION ALL
    SELECT TO_TIMESTAMP_LTZ("event_begin_time" / 1000000), "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2012
    UNION ALL
    SELECT TO_TIMESTAMP_LTZ("event_begin_time" / 1000000), "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2013
    UNION ALL
    SELECT TO_TIMESTAMP_LTZ("event_begin_time" / 1000000), "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2014
    UNION ALL
    SELECT TO_TIMESTAMP_LTZ("event_begin_time" / 1000000), "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2015
    UNION ALL
    SELECT TO_TIMESTAMP_LTZ("event_begin_time" / 1000000), "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2016
    UNION ALL
    SELECT TO_TIMESTAMP_LTZ("event_begin_time" / 1000000), "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2017
    UNION ALL
    SELECT TO_TIMESTAMP_LTZ("event_begin_time" / 1000000), "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2018
    UNION ALL
    SELECT TO_TIMESTAMP_LTZ("event_begin_time" / 1000000), "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2019
    UNION ALL
    SELECT TO_TIMESTAMP_LTZ("event_begin_time" / 1000000), "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2020
    UNION ALL
    SELECT TO_TIMESTAMP_LTZ("event_begin_time" / 1000000), "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2021
    UNION ALL
    SELECT TO_TIMESTAMP_LTZ("event_begin_time" / 1000000), "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2022
    UNION ALL
    SELECT TO_TIMESTAMP_LTZ("event_begin_time" / 1000000), "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2023
    UNION ALL
    SELECT TO_TIMESTAMP_LTZ("event_begin_time" / 1000000), "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2024
),
top_events AS (
    SELECT  evt_ts,
            "damage_property",
            EXTRACT(MONTH FROM evt_ts) AS evt_month,
            ROW_NUMBER() OVER (ORDER BY "damage_property" DESC NULLS LAST, evt_ts) AS rn
    FROM    union_storms
    WHERE   "damage_property" IS NOT NULL
),
top100 AS (
    SELECT * 
    FROM   top_events
    WHERE  rn <= 100
),
most_affected_month AS (
    SELECT  evt_month
    FROM    top100
    GROUP BY evt_month
    ORDER BY COUNT(*) DESC, evt_month
    LIMIT 1
)
SELECT COUNT(*) AS "TOTAL_EVENTS_IN_MOST_AFFECTED_MONTH"
FROM   top100
WHERE  EXTRACT(MONTH FROM evt_ts) = (SELECT evt_month FROM most_affected_month);