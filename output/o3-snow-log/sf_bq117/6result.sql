WITH union_events AS (

    /* 15 most-recent yearly severe–storm tables (2010–2024) */
    SELECT "event_begin_time",
           "damage_property"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2010
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
    UNION ALL SELECT "event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2024
),

/* keep only rows with non-null property damage,
   take the 100 highest-damage events */
top100 AS (
    SELECT *
    FROM union_events
    WHERE "damage_property" IS NOT NULL
    ORDER BY "damage_property" DESC NULLS LAST
    LIMIT 100
),

/* count how many of those top-damage events fall in each month */
monthly_counts AS (
    SELECT
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP_LTZ("event_begin_time" / 1000000)
        ) AS event_month,
        COUNT(*)                         AS event_count
    FROM top100
    WHERE "event_begin_time" IS NOT NULL
    GROUP BY event_month
)

/* return the largest monthly count (i.e., events in the most affected month) */
SELECT MAX(event_count) AS total_events_in_most_affected_month
FROM monthly_counts;