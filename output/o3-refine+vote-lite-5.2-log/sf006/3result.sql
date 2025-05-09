WITH base AS (
    SELECT
        "ID_STATE",
        "STATE_ABBREVIATION",
        "START_DATE",
        "END_DATE"
    FROM
        FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_BRANCH_ENTITIES
    WHERE
        "ID_COUNTRY" = 'country/USA'          -- keep only U.S. branches
        AND "CATEGORY" = 'Branch'             -- ensure branch‐level rows
),

-- branches active on 01‑Mar‑2020
active_2020 AS (
    SELECT
        "ID_STATE",
        "STATE_ABBREVIATION",
        COUNT(*) AS cnt_20200301
    FROM base
    WHERE
        "START_DATE" <= DATE '2020-03-01'
        AND ( "END_DATE" IS NULL OR "END_DATE" >= DATE '2020-03-01' )
    GROUP BY
        "ID_STATE",
        "STATE_ABBREVIATION"
),

-- branches active on 31‑Dec‑2021
active_2021 AS (
    SELECT
        "ID_STATE",
        "STATE_ABBREVIATION",
        COUNT(*) AS cnt_20211231
    FROM base
    WHERE
        "START_DATE" <= DATE '2021-12-31'
        AND ( "END_DATE" IS NULL OR "END_DATE" >= DATE '2021-12-31' )
    GROUP BY
        "ID_STATE",
        "STATE_ABBREVIATION"
)

SELECT
    COALESCE(a21."ID_STATE", a20."ID_STATE")               AS "STATE_GEO_ID",
    COALESCE(a21."STATE_ABBREVIATION", a20."STATE_ABBREVIATION") AS "STATE_ABBREV",
    COALESCE(a20.cnt_20200301, 0)                          AS "ACTIVE_BRANCHES_2020_03_01",
    COALESCE(a21.cnt_20211231, 0)                          AS "ACTIVE_BRANCHES_2021_12_31",
    CASE
        WHEN COALESCE(a20.cnt_20200301, 0) = 0 THEN NULL
        ELSE ROUND( ( COALESCE(a21.cnt_20211231, 0) - a20.cnt_20200301 )
                    * 100.0 / a20.cnt_20200301, 2 )
    END                                                    AS "PCT_CHANGE_2020_TO_2021"
FROM active_2020 a20
FULL OUTER JOIN active_2021 a21
  ON a20."ID_STATE" = a21."ID_STATE"
ORDER BY
    "STATE_ABBREV";