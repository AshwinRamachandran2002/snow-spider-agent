WITH baseline AS (   -- branches active on 01-Mar-2020
    SELECT
        "STATE_ABBREVIATION",
        COUNT(*) AS "active_2020_03_01"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_BRANCH_ENTITIES
    WHERE
        "STATE_ABBREVIATION" IS NOT NULL
        AND "START_DATE" <= '2020-03-01'
        AND ( "END_DATE" IS NULL OR "END_DATE" >= '2020-03-01' )
    GROUP BY
        "STATE_ABBREVIATION"
),
followup AS (        -- branches active on 31-Dec-2021
    SELECT
        "STATE_ABBREVIATION",
        COUNT(*) AS "active_2021_12_31"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_BRANCH_ENTITIES
    WHERE
        "STATE_ABBREVIATION" IS NOT NULL
        AND "START_DATE" <= '2021-12-31'
        AND ( "END_DATE" IS NULL OR "END_DATE" >= '2021-12-31' )
    GROUP BY
        "STATE_ABBREVIATION"
)

SELECT
    COALESCE(b."STATE_ABBREVIATION", f."STATE_ABBREVIATION")  AS "STATE_ABBREVIATION",
    COALESCE(b."active_2020_03_01", 0)                        AS "active_2020_03_01",
    COALESCE(f."active_2021_12_31", 0)                        AS "active_2021_12_31",
    CASE
        WHEN COALESCE(b."active_2020_03_01",0) = 0 THEN NULL
        ELSE ROUND(
            ( COALESCE(f."active_2021_12_31",0) - COALESCE(b."active_2020_03_01",0) )
            / COALESCE(b."active_2020_03_01",0) * 100
        , 2)
    END                                                      AS "pct_change"
FROM baseline b
FULL OUTER JOIN followup f
       ON b."STATE_ABBREVIATION" = f."STATE_ABBREVIATION"
ORDER BY
    "pct_change" DESC NULLS LAST;