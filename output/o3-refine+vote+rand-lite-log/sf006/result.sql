WITH branch_status AS (
    SELECT
        "STATE_ABBREVIATION"                        AS "STATE",
        /* Active on 2020‑03‑01 ? */
        CASE
            WHEN "START_DATE" <= DATE '2020-03-01'
                 AND ( "END_DATE" IS NULL OR "END_DATE" >= DATE '2020-03-01' )
            THEN 1 ELSE 0
        END                                          AS "ACTIVE_2020",
        /* Active on 2021‑12‑31 ? */
        CASE
            WHEN "START_DATE" <= DATE '2021-12-31'
                 AND ( "END_DATE" IS NULL OR "END_DATE" >= DATE '2021-12-31' )
            THEN 1 ELSE 0
        END                                          AS "ACTIVE_2021"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_BRANCH_ENTITIES
    WHERE "CATEGORY"     = 'Branch'          -- use branch‑level entities
      AND "ID_COUNTRY"   = 'country/USA'     -- keep U.S. locations only
      AND "STATE_ABBREVIATION" IS NOT NULL   -- ignore records without state info
)

SELECT
    "STATE",
    SUM("ACTIVE_2020")                                         AS "BRANCHES_ACTIVE_2020_03_01",
    SUM("ACTIVE_2021")                                         AS "BRANCHES_ACTIVE_2021_12_31",
    ROUND(
          (SUM("ACTIVE_2021") - SUM("ACTIVE_2020"))
        * 100.0
        / NULLIF(SUM("ACTIVE_2020"),0)
    , 2)                                                       AS "PCT_CHANGE"
FROM branch_status
GROUP BY "STATE"
ORDER BY "STATE";