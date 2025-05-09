WITH recent AS (  -- all events from the past-15-year tables
    SELECT "damage_property","event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2009" UNION ALL
    SELECT "damage_property","event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2010" UNION ALL
    SELECT "damage_property","event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2011" UNION ALL
    SELECT "damage_property","event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2012" UNION ALL
    SELECT "damage_property","event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2013" UNION ALL
    SELECT "damage_property","event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2014" UNION ALL
    SELECT "damage_property","event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2015" UNION ALL
    SELECT "damage_property","event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2016" UNION ALL
    SELECT "damage_property","event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2017" UNION ALL
    SELECT "damage_property","event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2018" UNION ALL
    SELECT "damage_property","event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2019" UNION ALL
    SELECT "damage_property","event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2020" UNION ALL
    SELECT "damage_property","event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2021" UNION ALL
    SELECT "damage_property","event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2022" UNION ALL
    SELECT "damage_property","event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2023" UNION ALL
    SELECT "damage_property","event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2024"
),
top100 AS (        -- 100 highest-damage events
    SELECT "damage_property","event_begin_time"
    FROM recent
    WHERE "damage_property" IS NOT NULL
    ORDER BY "damage_property" DESC NULLS LAST
    LIMIT 100
),
ranked_month AS (  -- month with the most of those top events
    SELECT TO_CHAR(TO_TIMESTAMP_LTZ("event_begin_time"/1000000),'YYYY-MM') AS "year_month",
           COUNT(*) AS "events"
    FROM top100
    GROUP BY "year_month"
    ORDER BY "events" DESC
    LIMIT 1
)
SELECT "events"
FROM ranked_month;