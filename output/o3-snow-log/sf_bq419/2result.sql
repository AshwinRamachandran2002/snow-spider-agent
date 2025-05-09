WITH yearly_counts AS (

    /* -------- 1980 -------- */
    SELECT 1980 AS "year",
           "state",
           COUNT(*) AS "event_count"
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_1980"
    WHERE "state" IS NOT NULL
    GROUP BY "state"

    UNION ALL
    /* -------- 1981 -------- */
    SELECT 1981, "state", COUNT(*) 
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_1981"
    WHERE "state" IS NOT NULL
    GROUP BY "state"

    UNION ALL
    /* -------- 1982 -------- */
    SELECT 1982, "state", COUNT(*) 
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_1982"
    WHERE "state" IS NOT NULL
    GROUP BY "state"

    UNION ALL
    /* -------- 1983 -------- */
    SELECT 1983, "state", COUNT(*) 
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_1983"
    WHERE "state" IS NOT NULL
    GROUP BY "state"

    UNION ALL
    /* -------- 1984 -------- */
    SELECT 1984, "state", COUNT(*) 
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_1984"
    WHERE "state" IS NOT NULL
    GROUP BY "state"

    UNION ALL
    /* -------- 1985 -------- */
    SELECT 1985, "state", COUNT(*) 
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_1985"
    WHERE "state" IS NOT NULL
    GROUP BY "state"

    UNION ALL
    /* -------- 1986 -------- */
    SELECT 1986, "state", COUNT(*) 
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_1986"
    WHERE "state" IS NOT NULL
    GROUP BY "state"

    UNION ALL
    /* -------- 1987 -------- */
    SELECT 1987, "state", COUNT(*) 
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_1987"
    WHERE "state" IS NOT NULL
    GROUP BY "state"

    UNION ALL
    /* -------- 1988 -------- */
    SELECT 1988, "state", COUNT(*) 
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_1988"
    WHERE "state" IS NOT NULL
    GROUP BY "state"

    UNION ALL
    /* -------- 1989 -------- */
    SELECT 1989, "state", COUNT(*) 
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_1989"
    WHERE "state" IS NOT NULL
    GROUP BY "state"

    UNION ALL
    /* -------- 1990 -------- */
    SELECT 1990, "state", COUNT(*) 
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_1990"
    WHERE "state" IS NOT NULL
    GROUP BY "state"

    UNION ALL
    /* -------- 1991 -------- */
    SELECT 1991, "state", COUNT(*) 
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_1991"
    WHERE "state" IS NOT NULL
    GROUP BY "state"

    UNION ALL
    /* -------- 1992 -------- */
    SELECT 1992, "state", COUNT(*) 
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_1992"
    WHERE "state" IS NOT NULL
    GROUP BY "state"

    UNION ALL
    /* -------- 1993 -------- */
    SELECT 1993, "state", COUNT(*) 
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_1993"
    WHERE "state" IS NOT NULL
    GROUP BY "state"

    UNION ALL
    /* -------- 1994 -------- */
    SELECT 1994, "state", COUNT(*) 
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_1994"
    WHERE "state" IS NOT NULL
    GROUP BY "state"

    UNION ALL
    /* -------- 1995 -------- */
    SELECT 1995, "state", COUNT(*) 
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS."STORMS_1995"
    WHERE "state" IS NOT NULL
    GROUP BY "state"

),

/* keep only the top 1,000 states (effectively all) for each year */
top_states_per_year AS (
    SELECT *
    FROM yearly_counts
    QUALIFY ROW_NUMBER() OVER (PARTITION BY "year"
                               ORDER BY "event_count" DESC NULLS LAST) <= 1000
)

/* aggregate across all years and pick the 5 states with the most events */
SELECT
    "state",
    SUM("event_count") AS "total_events_1980_1995"
FROM top_states_per_year
GROUP BY "state"
ORDER BY "total_events_1980_1995" DESC NULLS LAST
LIMIT 5;