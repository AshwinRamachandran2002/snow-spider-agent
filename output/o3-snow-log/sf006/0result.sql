WITH "branches" AS (
    SELECT
        "ID_STATE",
        "STATE_ABBREVIATION",
        "START_DATE",
        "END_DATE"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_BRANCH_ENTITIES
    WHERE "ID_COUNTRY" = 'country/USA'        -- keep only U.S. locations
),

"state_counts" AS (
    SELECT
        "ID_STATE",
        "STATE_ABBREVIATION",
        /* active on 01-Mar-2020 */
        SUM(
            CASE
                WHEN "START_DATE" <= DATE '2020-03-01'
                     AND ( "END_DATE" IS NULL OR "END_DATE" >= DATE '2020-03-01' )
                THEN 1 ELSE 0
            END
        ) AS "ACTIVE_2020_03_01",

        /* active on 31-Dec-2021 */
        SUM(
            CASE
                WHEN "START_DATE" <= DATE '2021-12-31'
                     AND ( "END_DATE" IS NULL OR "END_DATE" >= DATE '2021-12-31' )
                THEN 1 ELSE 0
            END
        ) AS "ACTIVE_2021_12_31"
    FROM "branches"
    GROUP BY
        "ID_STATE",
        "STATE_ABBREVIATION"
)

SELECT
    "ID_STATE",
    "STATE_ABBREVIATION",
    "ACTIVE_2020_03_01",
    "ACTIVE_2021_12_31",
    /* percentage change from 01-Mar-2020 to 31-Dec-2021 */
    CASE
        WHEN "ACTIVE_2020_03_01" = 0 THEN NULL
        ELSE
            ( "ACTIVE_2021_12_31" - "ACTIVE_2020_03_01" )
            * 100.0 / "ACTIVE_2020_03_01"
    END AS "PERCENT_CHANGE"
FROM "state_counts"
ORDER BY "STATE_ABBREVIATION";