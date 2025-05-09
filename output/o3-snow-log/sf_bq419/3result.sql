/* 5 states with the highest number of storm events (1980-1995) –
   after first retaining only the 1 000 most-active states in each year */
WITH yearly_counts AS (
    /* ---- 1980 ---- */
    SELECT 1980 AS yr, "state", COUNT(*) AS events_in_year
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_1980
    GROUP BY "state"

    UNION ALL  /* ---- 1981 ---- */
    SELECT 1981, "state", COUNT(*) 
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_1981
    GROUP BY "state"

    UNION ALL  /* ---- 1982 ---- */
    SELECT 1982, "state", COUNT(*) 
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_1982
    GROUP BY "state"

    UNION ALL  /* ---- 1983 ---- */
    SELECT 1983, "state", COUNT(*) 
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_1983
    GROUP BY "state"

    UNION ALL  /* ---- 1984 ---- */
    SELECT 1984, "state", COUNT(*) 
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_1984
    GROUP BY "state"

    UNION ALL  /* ---- 1985 ---- */
    SELECT 1985, "state", COUNT(*) 
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_1985
    GROUP BY "state"

    UNION ALL  /* ---- 1986 ---- */
    SELECT 1986, "state", COUNT(*) 
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_1986
    GROUP BY "state"

    UNION ALL  /* ---- 1987 ---- */
    SELECT 1987, "state", COUNT(*) 
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_1987
    GROUP BY "state"

    UNION ALL  /* ---- 1988 ---- */
    SELECT 1988, "state", COUNT(*) 
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_1988
    GROUP BY "state"

    UNION ALL  /* ---- 1989 ---- */
    SELECT 1989, "state", COUNT(*) 
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_1989
    GROUP BY "state"

    UNION ALL  /* ---- 1990 ---- */
    SELECT 1990, "state", COUNT(*) 
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_1990
    GROUP BY "state"

    UNION ALL  /* ---- 1991 ---- */
    SELECT 1991, "state", COUNT(*) 
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_1991
    GROUP BY "state"

    UNION ALL  /* ---- 1992 ---- */
    SELECT 1992, "state", COUNT(*) 
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_1992
    GROUP BY "state"

    UNION ALL  /* ---- 1993 ---- */
    SELECT 1993, "state", COUNT(*) 
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_1993
    GROUP BY "state"

    UNION ALL  /* ---- 1994 ---- */
    SELECT 1994, "state", COUNT(*) 
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_1994
    GROUP BY "state"

    UNION ALL  /* ---- 1995 ---- */
    SELECT 1995, "state", COUNT(*) 
    FROM NOAA_DATA.NOAA_HISTORIC_SEVERE_STORMS.STORMS_1995
    GROUP BY "state"
),
ranked AS (
    SELECT
        yr,
        "state",
        events_in_year,
        ROW_NUMBER() OVER (PARTITION BY yr ORDER BY events_in_year DESC NULLS LAST) AS rn
    FROM yearly_counts
)
SELECT
    "state",
    SUM(events_in_year) AS total_events_1980_1995
FROM ranked
WHERE rn <= 1000            -- keep only the top 1 000 states each year
GROUP BY "state"
ORDER BY total_events_1980_1995 DESC NULLS LAST
LIMIT 5;