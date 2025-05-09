WITH base AS (
    /* keep only the two required years and derive the state code */
    SELECT
        SPLIT_PART("CoC_Number", '-', 1)                           AS state,
        "Count_Year"                                               AS year,
        COALESCE("Unsheltered_Homeless", 
                 "Unsheltered_Homeless_Individuals")               AS unsheltered
    FROM SDOH.SDOH_HUD_PIT_HOMELESSNESS.HUD_PIT_BY_COC
    WHERE "Count_Year" IN (2015, 2018)
),  
state_year_totals AS (
    /* total unsheltered people per state per year */
    SELECT
        state,
        year,
        SUM(unsheltered)                                           AS total_unsheltered
    FROM base
    GROUP BY state, year
),  
state_pct_change AS (
    /* percentage change from 2015 to 2018 for each state */
    SELECT
        s15.state,
        ((s18.total_unsheltered - s15.total_unsheltered)
         / NULLIF(s15.total_unsheltered,0)) * 100                 AS pct_change
    FROM state_year_totals s15
    JOIN state_year_totals s18
          ON s15.state = s18.state
         AND s15.year  = 2015
         AND s18.year  = 2018
),  
national_average AS (
    /* national average of the state-level percentage changes */
    SELECT AVG(pct_change) AS avg_pct_change
    FROM state_pct_change
    WHERE pct_change IS NOT NULL
),  
ranked_states AS (
    /* distance of each state’s change from the national average */
    SELECT
        spc.state,
        ABS(spc.pct_change - na.avg_pct_change)                    AS diff_from_avg
    FROM state_pct_change spc
    CROSS JOIN national_average na
)  
/* five states whose change is closest to the national average */
SELECT state
FROM ranked_states
ORDER BY diff_from_avg ASC NULLS LAST
LIMIT 5;