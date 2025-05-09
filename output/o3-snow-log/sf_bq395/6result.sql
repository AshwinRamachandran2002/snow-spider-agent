WITH state_year_totals AS (
    /* 1.  Sum unsheltered homeless counts for 2015 & 2018 by state               */
    SELECT
        SUBSTR("CoC_Number", 1, 2)                       AS "STATE",
        "Count_Year",
        SUM("Unsheltered_Homeless")                      AS "TOTAL_UNSHELTERED"
    FROM SDOH.SDOH_HUD_PIT_HOMELESSNESS.HUD_PIT_BY_COC
    WHERE "Count_Year" IN (2015, 2018)
    GROUP BY SUBSTR("CoC_Number", 1, 2), "Count_Year"
),
state_pivot AS (
    /* 2.  Place 2015 and 2018 totals on the same row                              */
    SELECT
        "STATE",
        MAX(CASE WHEN "Count_Year" = 2015 THEN "TOTAL_UNSHELTERED" END) AS "UNSHELTERED_2015",
        MAX(CASE WHEN "Count_Year" = 2018 THEN "TOTAL_UNSHELTERED" END) AS "UNSHELTERED_2018"
    FROM state_year_totals
    GROUP BY "STATE"
),
state_pct_change AS (
    /* 3.  Compute percentage change per state                                     */
    SELECT
        "STATE",
        "UNSHELTERED_2015",
        "UNSHELTERED_2018",
        CASE
            WHEN "UNSHELTERED_2015" IS NULL OR "UNSHELTERED_2015" = 0 THEN NULL
            ELSE ("UNSHELTERED_2018" - "UNSHELTERED_2015") * 100.0 / "UNSHELTERED_2015"
        END AS "PCT_CHANGE"
    FROM state_pivot
),
national_avg AS (
    /* 4.  National average of state percentage changes                            */
    SELECT AVG("PCT_CHANGE") AS "AVG_PCT_CHANGE"
    FROM state_pct_change
    WHERE "PCT_CHANGE" IS NOT NULL
)
/* 5.  Pick the five states whose change is closest to the national average       */
SELECT
    spc."STATE"
FROM state_pct_change spc
CROSS JOIN national_avg na
WHERE spc."PCT_CHANGE" IS NOT NULL
ORDER BY ABS(spc."PCT_CHANGE" - na."AVG_PCT_CHANGE") ASC NULLS LAST
LIMIT 5;