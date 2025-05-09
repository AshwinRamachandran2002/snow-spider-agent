WITH base AS (   -- all U.S. branch-level entities with their operating windows
    SELECT 
        "ID_STATE"          AS "STATE_GEO_ID",
        "STATE_ABBREVIATION",
        "START_DATE",
        "END_DATE"
    FROM "FINANCE__ECONOMICS"."CYBERSYN"."FINANCIAL_BRANCH_ENTITIES"
    WHERE "ID_COUNTRY" = 'country/USA'
),

active_2020 AS (   -- entities active on 2020-03-01
    SELECT 
        "STATE_GEO_ID",
        "STATE_ABBREVIATION",
        COUNT(*) AS "COUNT_2020"
    FROM base
    WHERE "START_DATE" <= '2020-03-01'
      AND ( "END_DATE" IS NULL OR "END_DATE" >= '2020-03-01')
    GROUP BY "STATE_GEO_ID", "STATE_ABBREVIATION"
),

active_2021 AS (   -- entities active on 2021-12-31
    SELECT 
        "STATE_GEO_ID",
        "STATE_ABBREVIATION",
        COUNT(*) AS "COUNT_2021"
    FROM base
    WHERE "START_DATE" <= '2021-12-31'
      AND ( "END_DATE" IS NULL OR "END_DATE" >= '2021-12-31')
    GROUP BY "STATE_GEO_ID", "STATE_ABBREVIATION"
)

SELECT
    COALESCE(a20."STATE_GEO_ID", a21."STATE_GEO_ID")              AS "STATE_GEO_ID",
    COALESCE(a20."STATE_ABBREVIATION", a21."STATE_ABBREVIATION")  AS "STATE_ABBREVIATION",
    COALESCE(a20."COUNT_2020", 0)                                 AS "COUNT_2020",
    COALESCE(a21."COUNT_2021", 0)                                 AS "COUNT_2021",
    CASE 
        WHEN COALESCE(a20."COUNT_2020", 0) = 0 THEN NULL
        ELSE ROUND(
                 ( COALESCE(a21."COUNT_2021", 0) - COALESCE(a20."COUNT_2020", 0) )
                 / a20."COUNT_2020" * 100
             , 4)
    END                                                           AS "PCT_CHANGE"
FROM active_2020 a20
FULL OUTER JOIN active_2021 a21
    ON a20."STATE_GEO_ID" = a21."STATE_GEO_ID"
ORDER BY "PCT_CHANGE" DESC NULLS LAST;