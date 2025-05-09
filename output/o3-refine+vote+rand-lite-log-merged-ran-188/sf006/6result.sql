WITH active_2020 AS (   -- Branches active on 1-Mar-2020
    SELECT 
        "STATE_ABBREVIATION"                         AS "STATE",
        COUNT(*)                                     AS "branches_active_2020_03_01"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_BRANCH_ENTITIES
    WHERE "START_DATE" <= '2020-03-01'
      AND ( "END_DATE" IS NULL OR "END_DATE" >= '2020-03-01' )
    GROUP BY "STATE_ABBREVIATION"
),
active_2021 AS (   -- Branches active on 31-Dec-2021
    SELECT 
        "STATE_ABBREVIATION"                         AS "STATE",
        COUNT(*)                                     AS "branches_active_2021_12_31"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_BRANCH_ENTITIES
    WHERE "START_DATE" <= '2021-12-31'
      AND ( "END_DATE" IS NULL OR "END_DATE" >= '2021-12-31' )
    GROUP BY "STATE_ABBREVIATION"
)

SELECT
    COALESCE(a20."STATE", a21."STATE")                               AS "STATE",
    COALESCE(a20."branches_active_2020_03_01", 0)                    AS "branches_active_2020_03_01",
    COALESCE(a21."branches_active_2021_12_31", 0)                    AS "branches_active_2021_12_31",
    CASE 
        WHEN COALESCE(a20."branches_active_2020_03_01", 0) = 0 THEN NULL
        ELSE ROUND(
            100.0 * ( COALESCE(a21."branches_active_2021_12_31", 0) 
                    - COALESCE(a20."branches_active_2020_03_01", 0) )
            /  COALESCE(a20."branches_active_2020_03_01", 0)
        , 2)
    END                                                              AS "percent_change"
FROM active_2020 a20
FULL OUTER JOIN active_2021 a21
  ON a20."STATE" = a21."STATE"
ORDER BY "STATE";