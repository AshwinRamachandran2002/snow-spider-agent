WITH all_events AS (
    /* 1.  Collect 15 years (2010-2024) of historic-storm events              */
    SELECT "event_begin_time","damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2010 UNION ALL
    SELECT "event_begin_time","damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2011 UNION ALL
    SELECT "event_begin_time","damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2012 UNION ALL
    SELECT "event_begin_time","damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2013 UNION ALL
    SELECT "event_begin_time","damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2014 UNION ALL
    SELECT "event_begin_time","damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2015 UNION ALL
    SELECT "event_begin_time","damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2016 UNION ALL
    SELECT "event_begin_time","damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2017 UNION ALL
    SELECT "event_begin_time","damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2018 UNION ALL
    SELECT "event_begin_time","damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2019 UNION ALL
    SELECT "event_begin_time","damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2020 UNION ALL
    SELECT "event_begin_time","damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2021 UNION ALL
    SELECT "event_begin_time","damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2022 UNION ALL
    SELECT "event_begin_time","damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2023 UNION ALL
    SELECT "event_begin_time","damage_property"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2024
),
/* 2.  Keep the 100 costliest events (property damage)                       */
top100 AS (
    SELECT "event_begin_time"
    FROM all_events
    ORDER BY "damage_property" DESC NULLS LAST
    LIMIT 100
),
/* 3.  Count how many of those fall in each calendar month                   */
month_counts AS (
    SELECT 
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ("event_begin_time"/1000000)) AS event_month,
        COUNT(*)                                                         AS events_in_month
    FROM top100
    GROUP BY event_month
)
/* 4.  Return the maximum count – i.e., total events in the most-affected month */
SELECT MAX(events_in_month) AS total_events_in_most_affected_month
FROM   month_counts;