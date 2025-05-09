WITH top_events AS (
  SELECT "event_id",
         "event_begin_time",
         "damage_property"
  FROM (
    SELECT "event_id", "event_begin_time", "damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2008"
    UNION ALL
    SELECT "event_id", "event_begin_time", "damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2009"
    UNION ALL
    SELECT "event_id", "event_begin_time", "damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2010"
    UNION ALL
    SELECT "event_id", "event_begin_time", "damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2011"
    UNION ALL
    SELECT "event_id", "event_begin_time", "damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2012"
    UNION ALL
    SELECT "event_id", "event_begin_time", "damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2013"
    UNION ALL
    SELECT "event_id", "event_begin_time", "damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2014"
    UNION ALL
    SELECT "event_id", "event_begin_time", "damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2015"
    UNION ALL
    SELECT "event_id", "event_begin_time", "damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2016"
    UNION ALL
    SELECT "event_id", "event_begin_time", "damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2017"
    UNION ALL
    SELECT "event_id", "event_begin_time", "damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2018"
    UNION ALL
    SELECT "event_id", "event_begin_time", "damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2019"
    UNION ALL
    SELECT "event_id", "event_begin_time", "damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2020"
    UNION ALL
    SELECT "event_id", "event_begin_time", "damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2021"
    UNION ALL
    SELECT "event_id", "event_begin_time", "damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2022"
    UNION ALL
    SELECT "event_id", "event_begin_time", "damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2023"
  ) AS "all_storms"
  WHERE "damage_property" IS NOT NULL AND "damage_property" > 0
  ORDER BY "damage_property" DESC NULLS LAST
  LIMIT 100
)
SELECT TO_VARCHAR(TO_TIMESTAMP_NTZ("event_begin_time" / 1e6), 'Month') AS "Month",
       COUNT(*) AS "Total_number_of_severe_storm_events"
FROM top_events
GROUP BY "Month"
ORDER BY "Total_number_of_severe_storm_events" DESC
LIMIT 1;