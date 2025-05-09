WITH state_year AS (
    /* keep only the two required years and pull the state abbreviation */
    SELECT
        SPLIT_PART("CoC_Number", '-', 1)              AS state_abbr,
        "Count_Year"                                  AS yr,
        COALESCE("Unsheltered_Homeless", 0)           AS unsheltered_cnt
    FROM SDOH.SDOH_HUD_PIT_HOMELESSNESS.HUD_PIT_BY_COC
    WHERE "Count_Year" IN (2015, 2018)
), 
state_totals AS (
    /* total unsheltered counts per state for each year */
    SELECT
        state_abbr,
        SUM(CASE WHEN yr = 2015 THEN unsheltered_cnt ELSE 0 END) AS unsheltered_2015,
        SUM(CASE WHEN yr = 2018 THEN unsheltered_cnt ELSE 0 END) AS unsheltered_2018
    FROM state_year
    GROUP BY state_abbr
), 
state_pct_change AS (
    /* percentage change per state */
    SELECT
        state_abbr,
        unsheltered_2015,
        unsheltered_2018,
        CASE 
            WHEN unsheltered_2015 > 0 THEN
                (unsheltered_2018 - unsheltered_2015) / unsheltered_2015 * 100
        END AS pct_change
    FROM state_totals
), 
national_avg AS (
    /* national average of state-level percentage changes */
    SELECT AVG(pct_change) AS avg_pct_change
    FROM state_pct_change
    WHERE pct_change IS NOT NULL
)
SELECT
    s.state_abbr
FROM state_pct_change s
JOIN national_avg n
  ON TRUE
WHERE s.pct_change IS NOT NULL
ORDER BY ABS(s.pct_change - n.avg_pct_change) ASC NULLS LAST
LIMIT 5;