/*  Top-5 states (abbreviations) with the most storm events 1980-1995
    – only the 1,000 most-active states in each year are counted        */
WITH all_events AS (
    /* -------- 1980-1995 historical storm tables -------- */
    SELECT 1980 AS yr, "state"
      FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_1980" UNION ALL
    SELECT 1981,        "state" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_1981" UNION ALL
    SELECT 1982,        "state" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_1982" UNION ALL
    SELECT 1983,        "state" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_1983" UNION ALL
    SELECT 1984,        "state" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_1984" UNION ALL
    SELECT 1985,        "state" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_1985" UNION ALL
    SELECT 1986,        "state" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_1986" UNION ALL
    SELECT 1987,        "state" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_1987" UNION ALL
    SELECT 1988,        "state" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_1988" UNION ALL
    SELECT 1989,        "state" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_1989" UNION ALL
    SELECT 1990,        "state" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_1990" UNION ALL
    SELECT 1991,        "state" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_1991" UNION ALL
    SELECT 1992,        "state" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_1992" UNION ALL
    SELECT 1993,        "state" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_1993" UNION ALL
    SELECT 1994,        "state" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_1994" UNION ALL
    SELECT 1995,        "state" FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_1995"
),
-- count events for each (year, state)
state_year_counts AS (
    SELECT yr,
           "state",
           COUNT(*) AS cnt
    FROM   all_events
    GROUP  BY yr, "state"
),
-- rank states within each year by event count
ranked AS (
    SELECT  yr,
            "state",
            cnt,
            ROW_NUMBER() OVER (PARTITION BY yr ORDER BY cnt DESC) AS rn
    FROM    state_year_counts
)
-- aggregate across years keeping only top-1000 states per year
SELECT  "state",
        SUM(cnt) AS total_events
FROM    ranked
WHERE   rn <= 1000
GROUP BY "state"
ORDER BY total_events DESC
LIMIT 5;