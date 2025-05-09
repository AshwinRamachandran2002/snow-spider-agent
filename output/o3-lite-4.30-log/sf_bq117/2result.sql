WITH all_years AS (   /* 2010‑2024 = last 15 years */
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2010" UNION ALL
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2011" UNION ALL
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2012" UNION ALL
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2013" UNION ALL
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2014" UNION ALL
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2015" UNION ALL
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2016" UNION ALL
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2017" UNION ALL
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2018" UNION ALL
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2019" UNION ALL
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2020" UNION ALL
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2021" UNION ALL
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2022" UNION ALL
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2023" UNION ALL
    SELECT "event_id","event_begin_time","damage_property" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2024"
),
/* ensure each event is counted once */
unique_events AS (
    SELECT *
    FROM all_years
    QUALIFY ROW_NUMBER() OVER (PARTITION BY "event_id" ORDER BY "damage_property" DESC) = 1
),
top100 AS (          /* 100 highest‑damage unique events */
    SELECT
        "event_id",
        TO_TIMESTAMP("event_begin_time" / 1000000) AS "evt_ts",
        "damage_property"
    FROM unique_events
    ORDER BY "damage_property" DESC NULLS LAST
    LIMIT 100
),
month_counts AS (    /* count those 100 per month */
    SELECT
        DATE_TRUNC('month',"evt_ts") AS "month_start",
        COUNT(*)                      AS "total_severe_storm_events"
    FROM top100
    GROUP BY "month_start"
)
SELECT
    TO_CHAR("month_start",'YYYY-MM')  AS "most_affected_month",
    "total_severe_storm_events"
FROM month_counts
ORDER BY "total_severe_storm_events" DESC, "most_affected_month"
LIMIT 1;