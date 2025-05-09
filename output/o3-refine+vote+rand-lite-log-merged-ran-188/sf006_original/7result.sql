WITH state_branch_counts AS (
    SELECT
        "STATE_ABBREVIATION",
        /* branches active on 1‑Mar‑2020 */
        SUM(
            CASE
                WHEN "START_DATE" <= DATE '2020-03-01'
                     AND ( "END_DATE" IS NULL OR "END_DATE" >= DATE '2020-03-01')
                THEN 1 ELSE 0
            END
        ) AS "ACTIVE_2020_03_01",
        /* branches active on 31‑Dec‑2021 */
        SUM(
            CASE
                WHEN "START_DATE" <= DATE '2021-12-31'
                     AND ( "END_DATE" IS NULL OR "END_DATE" >= DATE '2021-12-31')
                THEN 1 ELSE 0
            END
        ) AS "ACTIVE_2021_12_31"
    FROM "FINANCE__ECONOMICS"."CYBERSYN"."FINANCIAL_BRANCH_ENTITIES"
    /* restrict to U.S. entities (safety) */
    WHERE "ID_COUNTRY" = 'country/USA'
    GROUP BY "STATE_ABBREVIATION"
)

SELECT
    "STATE_ABBREVIATION",
    "ACTIVE_2020_03_01",
    "ACTIVE_2021_12_31",
    CASE
        WHEN "ACTIVE_2020_03_01" = 0 THEN NULL
        ELSE ROUND(
               ( "ACTIVE_2021_12_31" - "ACTIVE_2020_03_01") 
               / "ACTIVE_2020_03_01" * 100, 2
             )
    END AS "PERCENT_CHANGE"
FROM state_branch_counts
ORDER BY "STATE_ABBREVIATION";