WITH
/* -----------------------------------------------------------------
   Count branches active on 01‑Mar‑2020 (pandemic reference date)
------------------------------------------------------------------*/
active_2020 AS (
    SELECT
        "STATE_ABBREVIATION"      AS state,
        COUNT(*)                  AS active_2020_03_01
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_BRANCH_ENTITIES
    WHERE "CATEGORY"    = 'Branch'
      AND "START_DATE" <= '2020-03-01'
      AND ( "END_DATE" IS NULL OR "END_DATE" >= '2020-03-01' )
    GROUP BY "STATE_ABBREVIATION"
),
/* -----------------------------------------------------------------
   Count branches active on 31‑Dec‑2021
------------------------------------------------------------------*/
active_2021 AS (
    SELECT
        "STATE_ABBREVIATION"      AS state,
        COUNT(*)                  AS active_2021_12_31
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_BRANCH_ENTITIES
    WHERE "CATEGORY"    = 'Branch'
      AND "START_DATE" <= '2021-12-31'
      AND ( "END_DATE" IS NULL OR "END_DATE" >= '2021-12-31' )
    GROUP BY "STATE_ABBREVIATION"
)
/* -----------------------------------------------------------------
   Combine snapshots and compute percentage change (4‑decimal precision)
------------------------------------------------------------------*/
SELECT
    COALESCE(a20.state, a21.state)                                   AS state,
    COALESCE(a20.active_2020_03_01, 0)                               AS active_2020_03_01,
    COALESCE(a21.active_2021_12_31, 0)                               AS active_2021_12_31,
    CASE
        WHEN COALESCE(a20.active_2020_03_01, 0) = 0 THEN NULL
        ELSE ROUND(
                 ( COALESCE(a21.active_2021_12_31, 0)
                 -  COALESCE(a20.active_2020_03_01, 0) )
                 * 100.0
                 / COALESCE(a20.active_2020_03_01, 0),
                 4
             )
    END                                                              AS percent_change
FROM active_2020 a20
FULL OUTER JOIN active_2021 a21
  ON a20.state = a21.state
ORDER BY state;