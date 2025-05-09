/*  For every U.S. state:
      • Count branches active on 2020-03-01
      • Count branches active on 2021-12-31
      • Compute % change between the two totals
*/
WITH active_2020 AS (   -- branches active on 1-Mar-2020
    SELECT
        "ID_STATE"           AS state_geo,
        COUNT(*)             AS cnt_2020
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_BRANCH_ENTITIES
    WHERE "START_DATE" <= '2020-03-01'
      AND ( "END_DATE" IS NULL OR "END_DATE" >= '2020-03-01' )
    GROUP BY "ID_STATE"
),
active_2021 AS (   -- branches active on 31-Dec-2021
    SELECT
        "ID_STATE"           AS state_geo,
        COUNT(*)             AS cnt_2021
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_BRANCH_ENTITIES
    WHERE "START_DATE" <= '2021-12-31'
      AND ( "END_DATE" IS NULL OR "END_DATE" >= '2021-12-31' )
    GROUP BY "ID_STATE"
)
SELECT
    g."GEO_NAME"                           AS "state_name",
    COALESCE(a20.cnt_2020, 0)              AS "branches_2020_03_01",
    COALESCE(a21.cnt_2021, 0)              AS "branches_2021_12_31",
    CASE
        WHEN COALESCE(a20.cnt_2020, 0) = 0 THEN NULL
        ELSE ROUND(
              (COALESCE(a21.cnt_2021, 0) - a20.cnt_2020) * 100.0
              / a20.cnt_2020
             , 2)
    END                                    AS "pct_change"
FROM FINANCE__ECONOMICS.CYBERSYN.GEOGRAPHY_INDEX g
LEFT JOIN active_2020 a20 ON g."GEO_ID" = a20.state_geo
LEFT JOIN active_2021 a21 ON g."GEO_ID" = a21.state_geo
WHERE g."LEVEL" = 'State'                 -- limit to U.S. states & equivalents
ORDER BY "pct_change" DESC NULLS LAST;