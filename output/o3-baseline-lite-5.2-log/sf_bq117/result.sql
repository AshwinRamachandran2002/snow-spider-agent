WITH union_events AS (    -- gather the past‑15‑year storm records with property‑damage values
    SELECT "event_begin_time",
           "damage_property"
    FROM (
        SELECT "event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2010
        UNION ALL
        SELECT "event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2011
        UNION ALL
        SELECT "event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2012
        UNION ALL
        SELECT "event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2013
        UNION ALL
        SELECT "event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2014
        UNION ALL
        SELECT "event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2015
        UNION ALL
        SELECT "event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2016
        UNION ALL
        SELECT "event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2017
        UNION ALL
        SELECT "event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2018
        UNION ALL
        SELECT "event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2019
        UNION ALL
        SELECT "event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2020
        UNION ALL
        SELECT "event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2021
        UNION ALL
        SELECT "event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2022
        UNION ALL
        SELECT "event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2023
        UNION ALL
        SELECT "event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2024
    )
    WHERE "damage_property" IS NOT NULL
      AND "event_begin_time" IS NOT NULL
),
top_100 AS (              -- keep only the 100 costliest events
    SELECT MONTH(TO_TIMESTAMP_LTZ("event_begin_time" / 1000000)) AS month_num
    FROM union_events
    QUALIFY ROW_NUMBER() OVER (ORDER BY "damage_property" DESC NULLS LAST, "event_begin_time") <= 100
),
month_counts AS (         -- count events per month within those 100
    SELECT month_num,
           COUNT(*) AS event_count
    FROM top_100
    GROUP BY month_num
)
SELECT event_count         -- final answer: number of events in the most affected month
FROM month_counts
ORDER BY event_count DESC, month_num
LIMIT 1;