WITH state_branch_counts AS (
    SELECT
        "STATE_ABBREVIATION"                                                  AS "STATE",
        -- Branches active on 2020-03-01
        SUM(
            CASE
                WHEN CAST("START_DATE" AS DATE) <= DATE '2020-03-01'
                     AND ( "END_DATE" IS NULL OR CAST("END_DATE" AS DATE) >= DATE '2020-03-01' )
                THEN 1 ELSE 0
            END
        )                                                                     AS "BRANCHES_2020_03_01",
        -- Branches active on 2021-12-31
        SUM(
            CASE
                WHEN CAST("START_DATE" AS DATE) <= DATE '2021-12-31'
                     AND ( "END_DATE" IS NULL OR CAST("END_DATE" AS DATE) >= DATE '2021-12-31' )
                THEN 1 ELSE 0
            END
        )                                                                     AS "BRANCHES_2021_12_31"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_BRANCH_ENTITIES
    WHERE "ID_COUNTRY" = 'country/USA'                -- restrict to U.S. branches
          AND "STATE_ABBREVIATION" IS NOT NULL         -- ensure state present
    GROUP BY "STATE_ABBREVIATION"
)

SELECT
    "STATE",
    "BRANCHES_2020_03_01",
    "BRANCHES_2021_12_31",
    CASE
        WHEN "BRANCHES_2020_03_01" = 0 THEN NULL
        ELSE ROUND( ( "BRANCHES_2021_12_31" - "BRANCHES_2020_03_01" )
                    * 100.0
                    / "BRANCHES_2020_03_01", 2)
    END                                                                   AS "PCT_CHANGE"
FROM state_branch_counts
ORDER BY "STATE";