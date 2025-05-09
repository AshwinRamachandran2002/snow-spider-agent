WITH all_events AS (
  SELECT "event_begin_time", "damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2008"
  UNION ALL
  SELECT "event_begin_time", "damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2009"
  UNION ALL
  SELECT "event_begin_time", "damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2010"
  UNION ALL
  SELECT "event_begin_time", "damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2011"
  UNION ALL
  SELECT "event_begin_time", "damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2012"
  UNION ALL
  SELECT "event_begin_time", "damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2013"
  UNION ALL
  SELECT "event_begin_time", "damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2014"
  UNION ALL
  SELECT "event_begin_time", "damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2015"
  UNION ALL
  SELECT "event_begin_time", "damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2016"
  UNION ALL
  SELECT "event_begin_time", "damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2017"
  UNION ALL
  SELECT "event_begin_time", "damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2018"
  UNION ALL
  SELECT "event_begin_time", "damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2019"
  UNION ALL
  SELECT "event_begin_time", "damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2020"
  UNION ALL
  SELECT "event_begin_time", "damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2021"
  UNION ALL
  SELECT "event_begin_time", "damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2022"
  UNION ALL
  SELECT "event_begin_time", "damage_property" FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2023"
),
all_events_with_numeric_damage AS (
  SELECT
    "event_begin_time",
    CASE
      WHEN UPPER(RIGHT(TRIM("damage_property"), 1)) = 'K' THEN
        TO_NUMBER(LEFT(TRIM("damage_property"), LENGTH(TRIM("damage_property")) - 1)) * 1000
      WHEN UPPER(RIGHT(TRIM("damage_property"), 1)) = 'M' THEN
        TO_NUMBER(LEFT(TRIM("damage_property"), LENGTH(TRIM("damage_property")) - 1)) * 1000000
      WHEN UPPER(RIGHT(TRIM("damage_property"), 1)) = 'B' THEN
        TO_NUMBER(LEFT(TRIM("damage_property"), LENGTH(TRIM("damage_property")) - 1)) * 1000000000
      ELSE
        TO_NUMBER(TRIM("damage_property"))
    END AS "damage_property_numeric"
  FROM all_events
  WHERE "damage_property" IS NOT NULL AND TRIM("damage_property") <> ''
),
top_100_events AS (
  SELECT "event_begin_time", "damage_property_numeric"
  FROM all_events_with_numeric_damage
  WHERE "damage_property_numeric" IS NOT NULL AND "damage_property_numeric" > 0
  ORDER BY "damage_property_numeric" DESC NULLS LAST
  LIMIT 100
)
SELECT 
  EXTRACT(MONTH FROM TO_TIMESTAMP_NTZ("event_begin_time" / 1000)) AS "Month",
  COUNT(*) AS "Total_number_of_severe_storm_events"
FROM top_100_events
GROUP BY "Month"
ORDER BY "Total_number_of_severe_storm_events" DESC
LIMIT 1;