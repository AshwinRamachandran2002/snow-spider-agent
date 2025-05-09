/*  For each U.S. state, compare how many financial-institution branches were
    active on 01-Mar-2020 versus 31-Dec-2021 and compute the percentage change. */

WITH
-- Branches deemed active on 01-Mar-2020
active_2020 AS (
    SELECT
        "STATE_ABBREVIATION"           AS state,
        COUNT(*)                       AS cnt_2020
    FROM FINANCE__ECONOMICS.CYBERSYN."FINANCIAL_BRANCH_ENTITIES"
    WHERE
          "STATE_ABBREVIATION" IS NOT NULL
      AND "START_DATE"               <= '2020-03-01'
      AND ( "END_DATE" IS NULL OR "END_DATE" >= '2020-03-01' )
    GROUP BY 1
),

-- Branches deemed active on 31-Dec-2021
active_2021 AS (
    SELECT
        "STATE_ABBREVIATION"           AS state,
        COUNT(*)                       AS cnt_2021
    FROM FINANCE__ECONOMICS.CYBERSYN."FINANCIAL_BRANCH_ENTITIES"
    WHERE
          "STATE_ABBREVIATION" IS NOT NULL
      AND "START_DATE"               <= '2021-12-31'
      AND ( "END_DATE" IS NULL OR "END_DATE" >= '2021-12-31' )
    GROUP BY 1
)

SELECT
    COALESCE(a20.state, a21.state)                    AS "STATE",
    COALESCE(a20.cnt_2020, 0)                         AS "ACTIVE_ON_2020_03_01",
    COALESCE(a21.cnt_2021, 0)                         AS "ACTIVE_ON_2021_12_31",
    CASE
        WHEN COALESCE(a20.cnt_2020, 0) = 0 THEN NULL
        ELSE ROUND( (COALESCE(a21.cnt_2021, 0) - a20.cnt_2020)
                    * 100.0 / a20.cnt_2020, 2 )
    END                                               AS "PERCENT_CHANGE"
FROM active_2020 a20
FULL JOIN active_2021 a21
  ON a20.state = a21.state
ORDER BY "STATE";