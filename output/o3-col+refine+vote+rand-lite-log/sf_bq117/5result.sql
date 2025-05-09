WITH union_events AS (
    SELECT "event_id", "event_begin_time", "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2010
    UNION ALL SELECT "event_id", "event_begin_time", "damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2011
    UNION ALL SELECT "event_id", "event_begin_time", "damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2012
    UNION ALL SELECT "event_id", "event_begin_time", "damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2013
    UNION ALL SELECT "event_id", "event_begin_time", "damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2014
    UNION ALL SELECT "event_id", "event_begin_time", "damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2015
    UNION ALL SELECT "event_id", "event_begin_time", "damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2016
    UNION ALL SELECT "event_id", "event_begin_time", "damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2017
    UNION ALL SELECT "event_id", "event_begin_time", "damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2018
    UNION ALL SELECT "event_id", "event_begin_time", "damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2019
    UNION ALL SELECT "event_id", "event_begin_time", "damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2020
    UNION ALL SELECT "event_id", "event_begin_time", "damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2021
    UNION ALL SELECT "event_id", "event_begin_time", "damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2022
    UNION ALL SELECT "event_id", "event_begin_time", "damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2023
    UNION ALL SELECT "event_id", "event_begin_time", "damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2024
),
ranked AS (
    SELECT
        "event_id",
        "damage_property",
        TO_CHAR(TO_TIMESTAMP_LTZ("event_begin_time" / 1000000), 'YYYY-MM') AS "year_month",
        ROW_NUMBER() OVER (ORDER BY "damage_property" DESC NULLS LAST) AS rn
    FROM union_events
),
top100 AS (
    SELECT * 
    FROM ranked 
    WHERE rn <= 100
)
SELECT 
    "year_month",
    COUNT(*) AS "events_in_month"
FROM top100
GROUP BY "year_month"
ORDER BY "events_in_month" DESC
LIMIT 1;