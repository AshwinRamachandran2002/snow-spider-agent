WITH storms AS (
    /* collect all severe–storm records from the most‑recent 15 years */
    SELECT "event_begin_time",
           "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2009
    UNION ALL SELECT "event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2010
    UNION ALL SELECT "event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2011
    UNION ALL SELECT "event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2012
    UNION ALL SELECT "event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2013
    UNION ALL SELECT "event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2014
    UNION ALL SELECT "event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2015
    UNION ALL SELECT "event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2016
    UNION ALL SELECT "event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2017
    UNION ALL SELECT "event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2018
    UNION ALL SELECT "event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2019
    UNION ALL SELECT "event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2020
    UNION ALL SELECT "event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2021
    UNION ALL SELECT "event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2022
    UNION ALL SELECT "event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2023
),
top100 AS (   -- 100 highest‑loss events
    SELECT  "event_begin_time"
    FROM (
        SELECT  "event_begin_time",
                ROW_NUMBER() OVER (ORDER BY "damage_property" DESC NULLS LAST,
                                            "event_begin_time") AS rn
        FROM storms
        WHERE "damage_property" IS NOT NULL
    )
    WHERE rn <= 100
),
month_counts AS (  -- count how many of those events happen in each month
    SELECT  EXTRACT(MONTH FROM TO_TIMESTAMP_LTZ("event_begin_time"/1000000)) AS month_num,
            COUNT(*) AS events_in_month
    FROM top100
    GROUP BY month_num
)
SELECT events_in_month AS total_events
FROM   month_counts
ORDER  BY events_in_month DESC, month_num
LIMIT  1;