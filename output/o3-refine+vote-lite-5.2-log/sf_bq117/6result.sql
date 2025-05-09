WITH combined AS (

    /* 15 most‑recent yearly tables (2010‑2024 inclusive) */
    SELECT "event_begin_time", "damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2010
    UNION ALL SELECT "event_begin_time", "damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2011
    UNION ALL SELECT "event_begin_time", "damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2012
    UNION ALL SELECT "event_begin_time", "damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2013
    UNION ALL SELECT "event_begin_time", "damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2014
    UNION ALL SELECT "event_begin_time", "damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2015
    UNION ALL SELECT "event_begin_time", "damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2016
    UNION ALL SELECT "event_begin_time", "damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2017
    UNION ALL SELECT "event_begin_time", "damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2018
    UNION ALL SELECT "event_begin_time", "damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2019
    UNION ALL SELECT "event_begin_time", "damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2020
    UNION ALL SELECT "event_begin_time", "damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2021
    UNION ALL SELECT "event_begin_time", "damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2022
    UNION ALL SELECT "event_begin_time", "damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2023
    UNION ALL SELECT "event_begin_time", "damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2024
),

top_100 AS (
    /* highest 100 property‑damage events */
    SELECT *
      FROM combined
     WHERE "damage_property" IS NOT NULL
     ORDER BY "damage_property" DESC NULLS LAST
     LIMIT 100
),

most_affected_month AS (
    /* identify the month having the greatest number of those 100 events */
    SELECT
        EXTRACT(MONTH FROM TO_TIMESTAMP_LTZ("event_begin_time" / 1000000))  AS month_no,
        COUNT(*)                                                            AS evt_cnt
      FROM top_100
     GROUP BY month_no
     ORDER BY evt_cnt DESC, month_no
     LIMIT 1
)

SELECT COUNT(*) AS "TOTAL_EVENTS_IN_MOST_AFFECTED_MONTH"
  FROM top_100
 WHERE EXTRACT(MONTH FROM TO_TIMESTAMP_LTZ("event_begin_time" / 1000000))
       = (SELECT month_no FROM most_affected_month);