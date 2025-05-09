WITH union_events AS (
    SELECT "damage_property"         AS dmg ,
           "event_begin_time"        AS evt_time
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2010
    UNION ALL SELECT "damage_property", "event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2011
    UNION ALL SELECT "damage_property", "event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2012
    UNION ALL SELECT "damage_property", "event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2013
    UNION ALL SELECT "damage_property", "event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2014
    UNION ALL SELECT "damage_property", "event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2015
    UNION ALL SELECT "damage_property", "event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2016
    UNION ALL SELECT "damage_property", "event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2017
    UNION ALL SELECT "damage_property", "event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2018
    UNION ALL SELECT "damage_property", "event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2019
    UNION ALL SELECT "damage_property", "event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2020
    UNION ALL SELECT "damage_property", "event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2021
    UNION ALL SELECT "damage_property", "event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2022
    UNION ALL SELECT "damage_property", "event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2023
    UNION ALL SELECT "damage_property", "event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2024
),
ranked AS (
    SELECT  dmg,
            evt_time,
            ROW_NUMBER() OVER (ORDER BY dmg DESC NULLS LAST) AS rn
    FROM union_events
    WHERE dmg IS NOT NULL
      AND dmg > 0
      AND evt_time IS NOT NULL
),
top100 AS (
    SELECT dmg,
           evt_time,
           EXTRACT(month
                   FROM TO_TIMESTAMP_LTZ(evt_time/1000000)) AS evt_month
    FROM ranked
    WHERE rn <= 100
),
month_counts AS (
    SELECT evt_month,
           COUNT(*) AS event_cnt
    FROM top100
    GROUP BY evt_month
    ORDER BY event_cnt DESC NULLS LAST,
             evt_month
    LIMIT 1
)
SELECT event_cnt AS total_events_in_most_affected_month
FROM month_counts;