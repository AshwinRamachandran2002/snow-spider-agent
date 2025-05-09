WITH state_branch_counts AS (
    SELECT 
        "STATE_ABBREVIATION",
        /* Branches active on 01-Mar-2020 */
        SUM(
            CASE 
                WHEN "START_DATE" <= DATE '2020-03-01'
                     AND ( "END_DATE" IS NULL OR "END_DATE" >= DATE '2020-03-01' )
                THEN 1 ELSE 0 
            END
        ) AS "ACTIVE_2020_03_01",
        /* Branches active on 31-Dec-2021 */
        SUM(
            CASE 
                WHEN "START_DATE" <= DATE '2021-12-31'
                     AND ( "END_DATE" IS NULL OR "END_DATE" >= DATE '2021-12-31' )
                THEN 1 ELSE 0 
            END
        ) AS "ACTIVE_2021_12_31"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_BRANCH_ENTITIES
    WHERE "CATEGORY" = 'Branch'
    GROUP BY "STATE_ABBREVIATION"
)

SELECT
    "STATE_ABBREVIATION"                                            AS "state",
    "ACTIVE_2020_03_01",
    "ACTIVE_2021_12_31",
    /* % change = (new − old) / old */
    ( ("ACTIVE_2021_12_31" - "ACTIVE_2020_03_01") * 100.0 )
      / NULLIF("ACTIVE_2020_03_01", 0)                              AS "pct_change"
FROM state_branch_counts
ORDER BY "pct_change" ASC NULLS LAST;