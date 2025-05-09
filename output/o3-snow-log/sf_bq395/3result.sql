WITH state_year_totals AS (
    SELECT
        SPLIT_PART("CoC_Number", '-', 1)      AS "STATE",
        "Count_Year",
        SUM("Unsheltered_Homeless")           AS "TOTAL_UNSHELTERED"
    FROM SDOH.SDOH_HUD_PIT_HOMELESSNESS.HUD_PIT_BY_COC
    WHERE "Count_Year" IN (2015, 2018)
    GROUP BY
        "STATE",
        "Count_Year"
),
state_pivot AS (
    SELECT
        "STATE",
        MAX(CASE WHEN "Count_Year" = 2015 THEN "TOTAL_UNSHELTERED" END) AS "TOTAL_2015",
        MAX(CASE WHEN "Count_Year" = 2018 THEN "TOTAL_UNSHELTERED" END) AS "TOTAL_2018"
    FROM state_year_totals
    GROUP BY "STATE"
),
state_changes AS (
    SELECT
        "STATE",
        (("TOTAL_2018" - "TOTAL_2015") / NULLIF("TOTAL_2015", 0)) * 100 AS "PCT_CHANGE"
    FROM state_pivot
    WHERE "TOTAL_2015" IS NOT NULL
      AND "TOTAL_2018" IS NOT NULL
      AND "TOTAL_2015" <> 0
),
national_avg AS (
    SELECT AVG("PCT_CHANGE") AS "AVG_PCT_CHANGE"
    FROM state_changes
)
SELECT
    sc."STATE"
FROM state_changes sc
CROSS JOIN national_avg na
ORDER BY ABS(sc."PCT_CHANGE" - na."AVG_PCT_CHANGE") ASC NULLS LAST
LIMIT 5;