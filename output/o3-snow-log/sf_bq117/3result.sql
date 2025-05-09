WITH all_recent_events AS (

    /* ------------------------------------------------------------------
       Collect the last 15 complete years of severe–storm events that have
       a reported property–damage value.
       ------------------------------------------------------------------ */
    SELECT "damage_property"        AS damage_usd ,
           "event_begin_time"       AS evt_begin_micro
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2010  UNION ALL
    SELECT "damage_property" ,       "event_begin_time"     FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2011 UNION ALL
    SELECT "damage_property" ,       "event_begin_time"     FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2012 UNION ALL
    SELECT "damage_property" ,       "event_begin_time"     FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2013 UNION ALL
    SELECT "damage_property" ,       "event_begin_time"     FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2014 UNION ALL
    SELECT "damage_property" ,       "event_begin_time"     FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2015 UNION ALL
    SELECT "damage_property" ,       "event_begin_time"     FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2016 UNION ALL
    SELECT "damage_property" ,       "event_begin_time"     FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2017 UNION ALL
    SELECT "damage_property" ,       "event_begin_time"     FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2018 UNION ALL
    SELECT "damage_property" ,       "event_begin_time"     FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2019 UNION ALL
    SELECT "damage_property" ,       "event_begin_time"     FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2020 UNION ALL
    SELECT "damage_property" ,       "event_begin_time"     FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2021 UNION ALL
    SELECT "damage_property" ,       "event_begin_time"     FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2022 UNION ALL
    SELECT "damage_property" ,       "event_begin_time"     FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2023 UNION ALL
    SELECT "damage_property" ,       "event_begin_time"     FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2024
    /* ------------------------------------------------------------------ */
),

top_100_damage AS (
    /* Pick the 100 most costly events (property-damage) */
    SELECT damage_usd,
           evt_begin_micro,
           /* Convert micro-seconds since epoch → TIMESTAMP and extract month */
           MONTH( TO_TIMESTAMP_LTZ( evt_begin_micro / 1e6 ) )  AS evt_month
    FROM   all_recent_events
    WHERE  damage_usd IS NOT NULL
    ORDER  BY damage_usd DESC NULLS LAST
    LIMIT  100
),

most_affected_month AS (
    /* Determine which calendar month contains the most of those 100 events */
    SELECT  evt_month
    FROM    top_100_damage
    GROUP   BY evt_month
    ORDER   BY COUNT(*) DESC
    LIMIT   1
)

SELECT COUNT(*) AS total_events_in_most_affected_month
FROM   top_100_damage
WHERE  evt_month = ( SELECT evt_month FROM most_affected_month );