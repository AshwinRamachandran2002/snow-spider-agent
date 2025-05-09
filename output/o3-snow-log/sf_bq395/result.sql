WITH state_year AS (
    -- total unsheltered people in each state (all CoCs) for 2015 and 2018
    SELECT
        SUBSTR("CoC_Number", 1, 2)                         AS "STATE",
        "Count_Year"                                       AS "YEAR",
        SUM("Unsheltered_Homeless")                        AS "UNSHELTERED_TOTAL"
    FROM SDOH.SDOH_HUD_PIT_HOMELESSNESS.HUD_PIT_BY_COC
    WHERE "Count_Year" IN (2015, 2018)
    GROUP BY 1, 2
),
state_change AS (
    -- percentage change 2015 ➜ 2018 for each state
    SELECT
        s15."STATE",
        s15."UNSHELTERED_TOTAL"                            AS "TOTAL_2015",
        s18."UNSHELTERED_TOTAL"                            AS "TOTAL_2018",
        CASE 
            WHEN s15."UNSHELTERED_TOTAL" = 0 THEN NULL
            ELSE ( (s18."UNSHELTERED_TOTAL" - s15."UNSHELTERED_TOTAL")
                   / s15."UNSHELTERED_TOTAL" ) * 100
        END                                                AS "PCT_CHANGE"
    FROM state_year s15
    JOIN state_year s18
          ON s15."STATE" = s18."STATE"
         AND s15."YEAR"  = 2015
         AND s18."YEAR"  = 2018
),
national_avg AS (
    -- national average of state percentage changes
    SELECT AVG("PCT_CHANGE") AS "AVG_PCT_CHANGE"
    FROM state_change
    WHERE "PCT_CHANGE" IS NOT NULL
),
state_diff AS (
    -- absolute distance of each state’s change from the national average
    SELECT
        sc."STATE",
        sc."PCT_CHANGE",
        na."AVG_PCT_CHANGE",
        ABS(sc."PCT_CHANGE" - na."AVG_PCT_CHANGE")         AS "DIFF_FROM_AVG"
    FROM state_change sc
    CROSS JOIN national_avg na
    WHERE sc."PCT_CHANGE" IS NOT NULL
)
SELECT "STATE"
FROM state_diff
ORDER BY "DIFF_FROM_AVG" ASC NULLS LAST, "STATE"
LIMIT 5;