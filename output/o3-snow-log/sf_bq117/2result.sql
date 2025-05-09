WITH union_events AS (

    /* 2010 – 2024 Severe-storm detail tables (include every table explicitly) */
    SELECT "damage_property"     AS "damage_property",
           "event_begin_time"    AS "event_begin_time"
    FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2010"  UNION ALL
    SELECT "damage_property","event_begin_time"  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2011" UNION ALL
    SELECT "damage_property","event_begin_time"  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2012" UNION ALL
    SELECT "damage_property","event_begin_time"  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2013" UNION ALL
    SELECT "damage_property","event_begin_time"  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2014" UNION ALL
    SELECT "damage_property","event_begin_time"  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2015" UNION ALL
    SELECT "damage_property","event_begin_time"  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2016" UNION ALL
    SELECT "damage_property","event_begin_time"  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2017" UNION ALL
    SELECT "damage_property","event_begin_time"  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2018" UNION ALL
    SELECT "damage_property","event_begin_time"  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2019" UNION ALL
    SELECT "damage_property","event_begin_time"  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2020" UNION ALL
    SELECT "damage_property","event_begin_time"  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2021" UNION ALL
    SELECT "damage_property","event_begin_time"  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2022" UNION ALL
    SELECT "damage_property","event_begin_time"  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2023" UNION ALL
    SELECT "damage_property","event_begin_time"  FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2024"

), recent_15yrs AS (

    /* keep events whose begin-time is within last 15 yrs & with non-null damage */
    SELECT  "damage_property",
            "event_begin_time",
            /* convert micro-second epoch to TIMESTAMP_NTZ */
            TO_TIMESTAMP_NTZ("event_begin_time" / 1e6)  AS "evt_ts"
    FROM    union_events
    WHERE   "damage_property" IS NOT NULL
      AND   TO_TIMESTAMP_NTZ("event_begin_time" / 1e6)
            >= DATEADD(year, -15, CURRENT_DATE())

), top100_damage AS (

    /* Top 100 highest–damage storms in the 15-year window */
    SELECT *
    FROM   recent_15yrs
    ORDER  BY "damage_property" DESC NULLS LAST
    LIMIT  100

), month_counts AS (

    /* count events per calendar month within those 100 records */
    SELECT  EXTRACT(month FROM "evt_ts")   AS "month_num",
            COUNT(*)                       AS "event_cnt"
    FROM    top100_damage
    GROUP  BY  EXTRACT(month FROM "evt_ts")

)

SELECT  MAX("event_cnt")  AS "total_events_in_most_affected_month"
FROM    month_counts;