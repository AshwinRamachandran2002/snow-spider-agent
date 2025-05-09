WITH state_activity AS (
    SELECT
        "STATE_ABBREVIATION"                                AS "STATE_ABBREVIATION",
        CASE
            WHEN "START_DATE" <= DATE '2020-03-01'
             AND ( "END_DATE" IS NULL OR "END_DATE" >= DATE '2020-03-01' )
            THEN 1 ELSE 0
        END                                                 AS "ACTIVE_2020",
        CASE
            WHEN "START_DATE" <= DATE '2021-12-31'
             AND ( "END_DATE" IS NULL OR "END_DATE" >= DATE '2021-12-31' )
            THEN 1 ELSE 0
        END                                                 AS "ACTIVE_2021"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_BRANCH_ENTITIES
    WHERE "ID_COUNTRY" = 'country/USA'
      AND "STATE_ABBREVIATION" IS NOT NULL
)

SELECT
    "STATE_ABBREVIATION",
    SUM("ACTIVE_2020")                                     AS "COUNT_2020_03_01",
    SUM("ACTIVE_2021")                                     AS "COUNT_2021_12_31",
    ROUND(
        (SUM("ACTIVE_2021") - SUM("ACTIVE_2020")) * 100.0
        / NULLIF(SUM("ACTIVE_2020"), 0),
        2
    )                                                      AS "PCT_CHANGE"
FROM state_activity
GROUP BY "STATE_ABBREVIATION"
ORDER BY "STATE_ABBREVIATION";