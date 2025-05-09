WITH events AS (   -- collect the last 15 yrs of historic‑storm records
    SELECT "damage_property","event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2010 UNION ALL
    SELECT "damage_property","event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2011 UNION ALL
    SELECT "damage_property","event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2012 UNION ALL
    SELECT "damage_property","event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2013 UNION ALL
    SELECT "damage_property","event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2014 UNION ALL
    SELECT "damage_property","event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2015 UNION ALL
    SELECT "damage_property","event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2016 UNION ALL
    SELECT "damage_property","event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2017 UNION ALL
    SELECT "damage_property","event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2018 UNION ALL
    SELECT "damage_property","event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2019 UNION ALL
    SELECT "damage_property","event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2020 UNION ALL
    SELECT "damage_property","event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2021 UNION ALL
    SELECT "damage_property","event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2022 UNION ALL
    SELECT "damage_property","event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2023 UNION ALL
    SELECT "damage_property","event_begin_time" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2024
),
filtered AS (      -- keep rows that have property‑damage values and derive month
    SELECT
        "damage_property",
        TO_CHAR(TO_TIMESTAMP("event_begin_time"/1000000),'MM') AS month
    FROM events
    WHERE "damage_property" IS NOT NULL
),
ranked AS (        -- rank all rows by damage to isolate the 100 costliest events
    SELECT
        month,
        ROW_NUMBER() OVER (ORDER BY "damage_property" DESC NULLS LAST) AS rn
    FROM filtered
),
top100 AS (        -- just the 100 highest‑damage events
    SELECT month
    FROM ranked
    WHERE rn <= 100
),
month_counts AS (  -- count how many of those 100 fell in each month
    SELECT month, COUNT(*) AS cnt
    FROM top100
    GROUP BY month
    ORDER BY cnt DESC, month ASC
    LIMIT 1           -- the single most‑affected month
)
SELECT cnt AS "total_events"
FROM month_counts;