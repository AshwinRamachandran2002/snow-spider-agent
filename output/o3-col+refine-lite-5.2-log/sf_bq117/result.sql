/*  total number of severe‑storm events that fall in the most‑affected
    month (by frequency) among the TOP‑100 highest‑damage events
    recorded during the last 15 years (2010‑2024)                 */
WITH last15 AS (               -- 15 yearly tables, 2010‑2024 inclusive
    SELECT "event_begin_time", "damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2010
    UNION ALL SELECT "event_begin_time", "damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2011
    UNION ALL SELECT "event_begin_time", "damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2012
    UNION ALL SELECT "event_begin_time", "damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2013
    UNION ALL SELECT "event_begin_time", "damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2014
    UNION ALL SELECT "event_begin_time", "damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2015
    UNION ALL SELECT "event_begin_time", "damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2016
    UNION ALL SELECT "event_begin_time", "damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2017
    UNION ALL SELECT "event_begin_time", "damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2018
    UNION ALL SELECT "event_begin_time", "damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2019
    UNION ALL SELECT "event_begin_time", "damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2020
    UNION ALL SELECT "event_begin_time", "damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2021
    UNION ALL SELECT "event_begin_time", "damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2022
    UNION ALL SELECT "event_begin_time", "damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2023
    UNION ALL SELECT "event_begin_time", "damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2024
),
top100 AS (                    -- top‑100 events by property damage
    SELECT *
      FROM last15
     WHERE "damage_property" IS NOT NULL
     ORDER BY "damage_property" DESC NULLS LAST
     LIMIT 100
),
most_month AS (                -- month appearing most often in top‑100
    SELECT EXTRACT(MONTH FROM TO_TIMESTAMP_LTZ("event_begin_time" / 1000000)) AS "month"
      FROM top100
     GROUP BY "month"
     ORDER BY COUNT(*) DESC, "month"
     LIMIT 1
)
SELECT COUNT(*) AS "total_events_in_most_affected_month"
  FROM top100 t
  JOIN most_month m
    ON EXTRACT(MONTH FROM TO_TIMESTAMP_LTZ(t."event_begin_time" / 1000000)) = m."month";