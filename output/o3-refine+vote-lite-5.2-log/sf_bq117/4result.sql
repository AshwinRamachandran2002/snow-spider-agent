WITH "EVENTS" AS (
    /*  ------- 2010 ─ 2024 severe–storm events with non‑zero property damage ------- */
    SELECT "event_begin_time", "damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2010
     WHERE "damage_property" IS NOT NULL
       AND "damage_property" > 0
       AND "event_begin_time" IS NOT NULL
    UNION ALL
    SELECT "event_begin_time", "damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2011
     WHERE "damage_property" IS NOT NULL
       AND "damage_property" > 0
       AND "event_begin_time" IS NOT NULL
    UNION ALL
    SELECT "event_begin_time", "damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2012
     WHERE "damage_property" IS NOT NULL
       AND "damage_property" > 0
       AND "event_begin_time" IS NOT NULL
    UNION ALL
    SELECT "event_begin_time", "damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2013
     WHERE "damage_property" IS NOT NULL
       AND "damage_property" > 0
       AND "event_begin_time" IS NOT NULL
    UNION ALL
    SELECT "event_begin_time", "damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2014
     WHERE "damage_property" IS NOT NULL
       AND "damage_property" > 0
       AND "event_begin_time" IS NOT NULL
    UNION ALL
    SELECT "event_begin_time", "damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2015
     WHERE "damage_property" IS NOT NULL
       AND "damage_property" > 0
       AND "event_begin_time" IS NOT NULL
    UNION ALL
    SELECT "event_begin_time", "damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2016
     WHERE "damage_property" IS NOT NULL
       AND "damage_property" > 0
       AND "event_begin_time" IS NOT NULL
    UNION ALL
    SELECT "event_begin_time", "damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2017
     WHERE "damage_property" IS NOT NULL
       AND "damage_property" > 0
       AND "event_begin_time" IS NOT NULL
    UNION ALL
    SELECT "event_begin_time", "damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2018
     WHERE "damage_property" IS NOT NULL
       AND "damage_property" > 0
       AND "event_begin_time" IS NOT NULL
    UNION ALL
    SELECT "event_begin_time", "damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2019
     WHERE "damage_property" IS NOT NULL
       AND "damage_property" > 0
       AND "event_begin_time" IS NOT NULL
    UNION ALL
    SELECT "event_begin_time", "damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2020
     WHERE "damage_property" IS NOT NULL
       AND "damage_property" > 0
       AND "event_begin_time" IS NOT NULL
    UNION ALL
    SELECT "event_begin_time", "damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2021
     WHERE "damage_property" IS NOT NULL
       AND "damage_property" > 0
       AND "event_begin_time" IS NOT NULL
    UNION ALL
    SELECT "event_begin_time", "damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2022
     WHERE "damage_property" IS NOT NULL
       AND "damage_property" > 0
       AND "event_begin_time" IS NOT NULL
    UNION ALL
    SELECT "event_begin_time", "damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2023
     WHERE "damage_property" IS NOT NULL
       AND "damage_property" > 0
       AND "event_begin_time" IS NOT NULL
    UNION ALL
    SELECT "event_begin_time", "damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2024
     WHERE "damage_property" IS NOT NULL
       AND "damage_property" > 0
       AND "event_begin_time" IS NOT NULL
),
/* --------------- pick the 100 costliest events --------------- */
"TOP100" AS (
    SELECT *
      FROM "EVENTS"
  ORDER BY "damage_property" DESC NULLS LAST
     LIMIT 100
),
/* --------------- count them by month --------------- */
"MONTH_COUNTS" AS (
    SELECT EXTRACT(MONTH FROM TO_TIMESTAMP_LTZ("event_begin_time" / 1000000))   AS "month",
           COUNT(*)                                                            AS "event_count"
      FROM "TOP100"
  GROUP BY "month"
)
/* --------------- result: number of events in most‑affected month --------------- */
SELECT "event_count"
  FROM "MONTH_COUNTS"
 ORDER BY "event_count" DESC, "month"
 LIMIT 1;