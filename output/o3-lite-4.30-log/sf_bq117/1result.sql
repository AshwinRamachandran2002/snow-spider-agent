WITH all_events AS (
    SELECT "event_id","event_begin_time","damage_property"
    FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2009"
    UNION ALL SELECT "event_id","event_begin_time","damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2010"
    UNION ALL SELECT "event_id","event_begin_time","damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2011"
    UNION ALL SELECT "event_id","event_begin_time","damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2012"
    UNION ALL SELECT "event_id","event_begin_time","damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2013"
    UNION ALL SELECT "event_id","event_begin_time","damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2014"
    UNION ALL SELECT "event_id","event_begin_time","damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2015"
    UNION ALL SELECT "event_id","event_begin_time","damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2016"
    UNION ALL SELECT "event_id","event_begin_time","damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2017"
    UNION ALL SELECT "event_id","event_begin_time","damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2018"
    UNION ALL SELECT "event_id","event_begin_time","damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2019"
    UNION ALL SELECT "event_id","event_begin_time","damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2020"
    UNION ALL SELECT "event_id","event_begin_time","damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2021"
    UNION ALL SELECT "event_id","event_begin_time","damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2022"
    UNION ALL SELECT "event_id","event_begin_time","damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2023"
    UNION ALL SELECT "event_id","event_begin_time","damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2024"
), top100 AS (   -- 100 costliest events since 2009‑01‑01
    SELECT "event_id","event_begin_time"
    FROM   all_events
    WHERE  "event_begin_time" >= 1230768000000000      -- 2009‑01‑01 in µs
      AND  "damage_property" > 0
    ORDER BY "damage_property" DESC
    LIMIT 100
), month_counts AS (
    SELECT TO_CHAR(TO_TIMESTAMP("event_begin_time"/1000000),'YYYY-MM') AS most_affected_month,
           COUNT(*)                                                    AS total_severe_storm_events
    FROM   top100
    GROUP BY 1
    ORDER BY total_severe_storm_events DESC, most_affected_month
    LIMIT 1
)
SELECT most_affected_month, total_severe_storm_events
FROM   month_counts;