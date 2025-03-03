WITH "combined_data" AS (
  SELECT "event_begin_time", "event_id", "damage_property"
  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2008"
  UNION ALL
  SELECT "event_begin_time", "event_id", "damage_property"
  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2009"
  UNION ALL
  SELECT "event_begin_time", "event_id", "damage_property"
  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2010"
  UNION ALL
  SELECT "event_begin_time", "event_id", "damage_property"
  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2011"
  UNION ALL
  SELECT "event_begin_time", "event_id", "damage_property"
  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2012"
  UNION ALL
  SELECT "event_begin_time", "event_id", "damage_property"
  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2013"
  UNION ALL
  SELECT "event_begin_time", "event_id", "damage_property"
  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2014"
  UNION ALL
  SELECT "event_begin_time", "event_id", "damage_property"
  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2015"
  UNION ALL
  SELECT "event_begin_time", "event_id", "damage_property"
  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2016"
  UNION ALL
  SELECT "event_begin_time", "event_id", "damage_property"
  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2017"
  UNION ALL
  SELECT "event_begin_time", "event_id", "damage_property"
  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2018"
  UNION ALL
  SELECT "event_begin_time", "event_id", "damage_property"
  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2019"
  UNION ALL
  SELECT "event_begin_time", "event_id", "damage_property"
  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2020"
  UNION ALL
  SELECT "event_begin_time", "event_id", "damage_property"
  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2021"
  UNION ALL
  SELECT "event_begin_time", "event_id", "damage_property"
  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2022"
  UNION ALL
  SELECT "event_begin_time", "event_id", "damage_property"
  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2023"
)
SELECT EXTRACT(MONTH FROM TO_TIMESTAMP("event_begin_time" / 1e6)) AS "Month",
       COUNT(*) AS "Total_number_of_severe_storm_events"
FROM (
  SELECT "event_begin_time"
  FROM "combined_data"
  WHERE "damage_property" IS NOT NULL
  ORDER BY "damage_property" DESC NULLS LAST
  LIMIT 100
) AS "top_100_events"
GROUP BY "Month"
ORDER BY "Total_number_of_severe_storm_events" DESC
LIMIT 1;