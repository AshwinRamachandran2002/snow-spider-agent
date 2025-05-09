WITH all_events AS (
    SELECT "event_begin_time",
           "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2010
    UNION ALL
    SELECT "event_begin_time",
           "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2011
    UNION ALL
    SELECT "event_begin_time",
           "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2012
    UNION ALL
    SELECT "event_begin_time",
           "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2013
    UNION ALL
    SELECT "event_begin_time",
           "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2014
    UNION ALL
    SELECT "event_begin_time",
           "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2015
    UNION ALL
    SELECT "event_begin_time",
           "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2016
    UNION ALL
    SELECT "event_begin_time",
           "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2017
    UNION ALL
    SELECT "event_begin_time",
           "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2018
    UNION ALL
    SELECT "event_begin_time",
           "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2019
    UNION ALL
    SELECT "event_begin_time",
           "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2020
    UNION ALL
    SELECT "event_begin_time",
           "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2021
    UNION ALL
    SELECT "event_begin_time",
           "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2022
    UNION ALL
    SELECT "event_begin_time",
           "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2023
    UNION ALL
    SELECT "event_begin_time",
           "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2024
),
filtered AS (
    SELECT
        "event_begin_time",
        "damage_property",
        MONTH(TO_TIMESTAMP_LTZ("event_begin_time" / 1000000)) AS event_month
    FROM all_events
    WHERE "damage_property" IS NOT NULL
),
top100 AS (
    SELECT *
    FROM filtered
    QUALIFY ROW_NUMBER() OVER (ORDER BY "damage_property" DESC NULLS LAST) <= 100
),
month_counts AS (
    SELECT
        event_month,
        COUNT(*) AS event_count
    FROM top100
    GROUP BY event_month
    ORDER BY event_count DESC, event_month
    LIMIT 1
)
SELECT event_count
FROM month_counts;