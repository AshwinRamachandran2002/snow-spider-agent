WITH state_year_totals AS (
    SELECT
        SUBSTR("CoC_Number", 1, 2)                         AS "STATE",
        "Count_Year"                                       AS "YEAR",
        SUM(COALESCE("Unsheltered_Homeless",
                     "Unsheltered_Homeless_Individuals",0)) AS "UNSHELTERED_TOTAL"
    FROM SDOH.SDOH_HUD_PIT_HOMELESSNESS."HUD_PIT_BY_COC"
    WHERE "Count_Year" IN (2015, 2018)
    GROUP BY
        SUBSTR("CoC_Number", 1, 2),
        "Count_Year"
),
state_change AS (
    SELECT
        t15."STATE",
        t15."UNSHELTERED_TOTAL"        AS "TOTAL_2015",
        t18."UNSHELTERED_TOTAL"        AS "TOTAL_2018",
        (t18."UNSHELTERED_TOTAL" - t15."UNSHELTERED_TOTAL")
        / NULLIF(t15."UNSHELTERED_TOTAL",0) * 100          AS "PCT_CHANGE"
    FROM  state_year_totals t15
    JOIN  state_year_totals t18
          ON  t15."STATE" = t18."STATE"
          AND t15."YEAR"  = 2015
          AND t18."YEAR"  = 2018
    WHERE t15."UNSHELTERED_TOTAL" IS NOT NULL
      AND t18."UNSHELTERED_TOTAL" IS NOT NULL
      AND t15."UNSHELTERED_TOTAL" <> 0
),
national_avg AS (
    SELECT AVG("PCT_CHANGE") AS "AVG_PCT_CHANGE"
    FROM   state_change
),
closest_states AS (
    SELECT
        sc."STATE",
        ABS(sc."PCT_CHANGE" - na."AVG_PCT_CHANGE") AS "DIFF_FROM_AVG"
    FROM   state_change sc
    CROSS  JOIN national_avg na
    ORDER  BY "DIFF_FROM_AVG" ASC NULLS LAST, sc."STATE"
    LIMIT  5
)
SELECT "STATE"
FROM   closest_states
ORDER  BY "STATE";