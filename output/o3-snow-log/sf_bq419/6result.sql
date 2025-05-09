WITH year_state AS (  -- collect state values for each year 1980-1995
    SELECT '1980' AS "yr", "state"
      FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1980"
    UNION ALL SELECT '1981', "state"
      FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1981"
    UNION ALL SELECT '1982', "state"
      FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1982"
    UNION ALL SELECT '1983', "state"
      FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1983"
    UNION ALL SELECT '1984', "state"
      FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1984"
    UNION ALL SELECT '1985', "state"
      FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1985"
    UNION ALL SELECT '1986', "state"
      FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1986"
    UNION ALL SELECT '1987', "state"
      FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1987"
    UNION ALL SELECT '1988', "state"
      FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1988"
    UNION ALL SELECT '1989', "state"
      FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1989"
    UNION ALL SELECT '1990', "state"
      FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1990"
    UNION ALL SELECT '1991', "state"
      FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1991"
    UNION ALL SELECT '1992', "state"
      FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1992"
    UNION ALL SELECT '1993', "state"
      FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1993"
    UNION ALL SELECT '1994', "state"
      FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1994"
    UNION ALL SELECT '1995', "state"
      FROM "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1995"
),
year_counts AS (      -- count events per state each year
    SELECT
        "yr",
        "state",
        COUNT(*) AS "year_state_events"
    FROM year_state
    GROUP BY "yr", "state"
),
top1000 AS (          -- keep only the 1,000 highest-count states per year
    SELECT *
    FROM (
        SELECT
            "yr",
            "state",
            "year_state_events",
            ROW_NUMBER() OVER (PARTITION BY "yr"
                               ORDER BY "year_state_events" DESC NULLS LAST) AS rn
        FROM year_counts
    )
    WHERE rn <= 1000
)
SELECT                -- final answer: 5 states with most retained events
    "state",
    SUM("year_state_events") AS "total_events_1980_1995"
FROM top1000
GROUP BY "state"
ORDER BY "total_events_1980_1995" DESC
LIMIT 5;