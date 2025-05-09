WITH base AS (
    SELECT
        SUBSTR("CoC_Number", 1, 2)                         AS state_abbrev,
        "Count_Year",
        COALESCE("Unsheltered_Homeless",
                 "Unsheltered_Homeless_Individuals")       AS unsheltered
    FROM SDOH.SDOH_HUD_PIT_HOMELESSNESS.HUD_PIT_BY_COC
    WHERE "Count_Year" IN (2015, 2018)
),
state_year AS (
    SELECT
        state_abbrev,
        "Count_Year"                                       AS yr,
        SUM(unsheltered)                                   AS total_unsheltered
    FROM base
    GROUP BY state_abbrev, "Count_Year"
),
state_change AS (
    SELECT
        s15.state_abbrev,
        ((s18.total_unsheltered - s15.total_unsheltered)
         / NULLIF(s15.total_unsheltered, 0)) * 100.0      AS pct_change
    FROM state_year s15
    JOIN state_year s18
      ON s15.state_abbrev = s18.state_abbrev
     AND s15.yr = 2015
     AND s18.yr = 2018
),
national_avg AS (
    SELECT AVG(pct_change) AS national_pct_change
    FROM state_change
),
diffs AS (
    SELECT
        sc.state_abbrev,
        sc.pct_change,
        na.national_pct_change,
        ABS(sc.pct_change - na.national_pct_change)        AS abs_diff
    FROM state_change sc
    CROSS JOIN national_avg na
)
SELECT state_abbrev
FROM diffs
ORDER BY abs_diff ASC NULLS LAST
LIMIT 5;