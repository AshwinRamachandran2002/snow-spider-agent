WITH all_events AS (             -- 1️⃣ gather the last-15-year catalogue
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2010 UNION ALL
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2011 UNION ALL
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2012 UNION ALL
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2013 UNION ALL
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2014 UNION ALL
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2015 UNION ALL
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2016 UNION ALL
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2017 UNION ALL
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2018 UNION ALL
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2019 UNION ALL
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2020 UNION ALL
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2021 UNION ALL
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2022 UNION ALL
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2023 UNION ALL
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2024
), 
top100 AS (                      -- 2️⃣ take the 100 costliest events
    SELECT "event_id","event_begin_time"
    FROM all_events
    WHERE "damage_property" IS NOT NULL
    ORDER BY "damage_property" DESC NULLS LAST
    LIMIT 100
), 
month_counts AS (                -- 3️⃣ tally how many fall in each calendar month
    SELECT 
        TO_CHAR(TO_TIMESTAMP_LTZ("event_begin_time"/1000000), 'MM') AS "month",
        COUNT(*)                                                   AS "event_cnt"
    FROM top100
    GROUP BY "month"
), 
most_affected AS (               -- 4️⃣ pick the month with the greatest tally
    SELECT "event_cnt"
    FROM month_counts
    ORDER BY "event_cnt" DESC
    LIMIT 1
)
SELECT 
    "event_cnt" AS "total_events_in_most_affected_month"
FROM most_affected;