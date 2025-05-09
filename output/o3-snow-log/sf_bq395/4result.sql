/* 1.  Aggregate unsheltered‐homeless counts for 2015 and 2018 by state
   2.  Compute each state’s % change
   3.  Find the national average of these % changes
   4.  Select the five states whose % change is closest to that average  */

WITH state_year_totals AS (
    SELECT
        SPLIT_PART("CoC_Number", '-', 1)                         AS state,
        "Count_Year"                                             AS yr,
        SUM("Unsheltered_Homeless")                              AS unsheltered_total
    FROM SDOH.SDOH_HUD_PIT_HOMELESSNESS.HUD_PIT_BY_COC
    WHERE "Count_Year" IN (2015, 2018)
    GROUP BY state, yr
),
state_pivot AS (
    SELECT
        state,
        MAX(CASE WHEN yr = 2015 THEN unsheltered_total END) AS unsheltered_2015,
        MAX(CASE WHEN yr = 2018 THEN unsheltered_total END) AS unsheltered_2018
    FROM state_year_totals
    GROUP BY state
),
state_pct_change AS (
    SELECT
        state,
        (unsheltered_2018 - unsheltered_2015) * 100.0 / unsheltered_2015 AS pct_change
    FROM state_pivot
    WHERE unsheltered_2015 > 0            -- avoid division by zero
          AND unsheltered_2018 IS NOT NULL
),
national_avg AS (
    SELECT AVG(pct_change) AS avg_pct_change
    FROM state_pct_change
),
state_vs_avg AS (
    SELECT
        s.state,
        ABS(s.pct_change - n.avg_pct_change) AS diff_from_avg
    FROM state_pct_change s
    CROSS JOIN national_avg n
)
SELECT state
FROM state_vs_avg
ORDER BY diff_from_avg ASC NULLS LAST
LIMIT 5;