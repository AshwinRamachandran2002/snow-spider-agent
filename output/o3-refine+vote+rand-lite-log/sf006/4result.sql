/*  Active financial branch entities per U.S. state
    – counts on 1‑Mar‑2020 and 31‑Dec‑2021
    – percentage change over the period                                   */

SELECT
    t."STATE_ABBREVIATION"                              AS "STATE",
    t."ACTIVE_2020_03_01"                               AS "BRANCHES_2020_03_01",
    t."ACTIVE_2021_12_31"                               AS "BRANCHES_2021_12_31",
    ROUND(
        (t."ACTIVE_2021_12_31" - t."ACTIVE_2020_03_01")
        * 100.0 / NULLIF(t."ACTIVE_2020_03_01", 0),
    2)                                                  AS "PERCENT_CHANGE"
FROM (
    SELECT
        "STATE_ABBREVIATION",
        /* branches active on 1‑Mar‑2020 */
        SUM(
            CASE
                WHEN "START_DATE" <= '2020-03-01'
                     AND ( "END_DATE" IS NULL
                           OR "END_DATE" >= '2020-03-01' )
                THEN 1 ELSE 0
            END
        ) AS "ACTIVE_2020_03_01",

        /* branches active on 31‑Dec‑2021 */
        SUM(
            CASE
                WHEN "START_DATE" <= '2021-12-31'
                     AND ( "END_DATE" IS NULL
                           OR "END_DATE" >= '2021-12-31' )
                THEN 1 ELSE 0
            END
        ) AS "ACTIVE_2021_12_31"
    FROM
        "FINANCE__ECONOMICS"."CYBERSYN"."FINANCIAL_BRANCH_ENTITIES"
    WHERE
        "CATEGORY" = 'Branch'                      -- only branch entities
        AND "ID_COUNTRY" = 'country/USA'           -- U.S. states only
        AND "STATE_ABBREVIATION" IS NOT NULL
    GROUP BY
        "STATE_ABBREVIATION"
) t
ORDER BY
    "STATE";