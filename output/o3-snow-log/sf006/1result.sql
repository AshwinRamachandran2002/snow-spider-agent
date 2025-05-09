WITH active_counts AS (

    /* --- branches active on 1-Mar-2020 --- */
    SELECT
        "STATE_ABBREVIATION"                       AS "STATE",
        DATE '2020-03-01'                          AS "REF_DATE",
        COUNT(*)                                   AS "ACTIVE_COUNT"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_BRANCH_ENTITIES
    WHERE "START_DATE" <= DATE '2020-03-01'
      AND ( "END_DATE" IS NULL OR "END_DATE" >= DATE '2020-03-01' )
    GROUP BY "STATE_ABBREVIATION"

    UNION ALL

    /* --- branches active on 31-Dec-2021 --- */
    SELECT
        "STATE_ABBREVIATION"                       AS "STATE",
        DATE '2021-12-31'                          AS "REF_DATE",
        COUNT(*)                                   AS "ACTIVE_COUNT"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_BRANCH_ENTITIES
    WHERE "START_DATE" <= DATE '2021-12-31'
      AND ( "END_DATE" IS NULL OR "END_DATE" >= DATE '2021-12-31' )
    GROUP BY "STATE_ABBREVIATION"
),

/* reshape the two rows per state into single row */
pivoted AS (
    SELECT
        "STATE",
        MAX(CASE WHEN "REF_DATE" = DATE '2020-03-01' THEN "ACTIVE_COUNT" END) AS "COUNT_2020_03_01",
        MAX(CASE WHEN "REF_DATE" = DATE '2021-12-31' THEN "ACTIVE_COUNT" END) AS "COUNT_2021_12_31"
    FROM active_counts
    GROUP BY "STATE"
)

SELECT
    "STATE",
    "COUNT_2020_03_01"                                            AS "ACTIVE_BRANCHES_2020_03_01",
    "COUNT_2021_12_31"                                            AS "ACTIVE_BRANCHES_2021_12_31",
    CASE
        WHEN "COUNT_2020_03_01" IS NULL OR "COUNT_2020_03_01" = 0
            THEN NULL
        ELSE ROUND( ( "COUNT_2021_12_31" - "COUNT_2020_03_01" )
                    * 100.0 / "COUNT_2020_03_01", 2)
    END                                                           AS "PERCENT_CHANGE"
FROM pivoted
ORDER BY "PERCENT_CHANGE" DESC NULLS LAST;