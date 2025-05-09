WITH union_events AS (

    /* ------------------------------------------------------------------
       Combine the Severe Storms records for the last-15-year tables
    ------------------------------------------------------------------ */
    SELECT "damage_property",
           "event_begin_time"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2009

    UNION ALL
    SELECT "damage_property","event_begin_time"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2010

    UNION ALL
    SELECT "damage_property","event_begin_time"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2011

    UNION ALL
    SELECT "damage_property","event_begin_time"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2012

    UNION ALL
    SELECT "damage_property","event_begin_time"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2013

    UNION ALL
    SELECT "damage_property","event_begin_time"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2014

    UNION ALL
    SELECT "damage_property","event_begin_time"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2015

    UNION ALL
    SELECT "damage_property","event_begin_time"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2016

    UNION ALL
    SELECT "damage_property","event_begin_time"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2017

    UNION ALL
    SELECT "damage_property","event_begin_time"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2018

    UNION ALL
    SELECT "damage_property","event_begin_time"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2019

    UNION ALL
    SELECT "damage_property","event_begin_time"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2020

    UNION ALL
    SELECT "damage_property","event_begin_time"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2021

    UNION ALL
    SELECT "damage_property","event_begin_time"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2022

    UNION ALL
    SELECT "damage_property","event_begin_time"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2023

    UNION ALL
    SELECT "damage_property","event_begin_time"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2024
),

/* ----------------------------------------------------------------------
   Keep only records within the last 15 years and having non-null damage
---------------------------------------------------------------------- */
recent_events AS (
    SELECT
        "damage_property",
        TO_TIMESTAMP_LTZ("event_begin_time" / 1000000) AS event_ts
    FROM union_events
    WHERE "damage_property" IS NOT NULL
      AND "event_begin_time" IS NOT NULL
      AND TO_TIMESTAMP_LTZ("event_begin_time" / 1000000)
            >= DATEADD(year, -15, CURRENT_DATE())
),

/* -------------------------------------------------------------
   Select the 100 events with the greatest property-damage value
------------------------------------------------------------- */
top_100 AS (
    SELECT *
    FROM recent_events
    ORDER BY "damage_property" DESC NULLS LAST
    LIMIT 100
),

/* -----------------------------------------
   Count how many of those events per month
----------------------------------------- */
monthly_counts AS (
    SELECT
        DATE_TRUNC('month', event_ts) AS month_start,
        COUNT(*)                      AS event_cnt
    FROM top_100
    GROUP BY month_start
)

/* -------------------------------------------------------------------
   Return the total number of events in the single most-affected month
------------------------------------------------------------------- */
SELECT event_cnt
FROM monthly_counts
ORDER BY event_cnt DESC
LIMIT 1;