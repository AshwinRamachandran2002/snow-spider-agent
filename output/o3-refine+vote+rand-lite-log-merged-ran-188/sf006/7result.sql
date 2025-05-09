/*  Active financial-branch counts by U.S. state
    – 2020-03-01   vs.   2021-12-31
    ----------------------------------------------------
    A branch is “active” on a reference date when
      START_DATE ≤ ref_date
      AND ( END_DATE IS NULL  OR  END_DATE ≥ ref_date )
*/
WITH state_counts AS (
    SELECT
        "STATE_ABBREVIATION",
        /* active on 1-Mar-2020 */
        SUM(
            CASE
                WHEN DATE '2020-03-01'
                     BETWEEN "START_DATE"
                     AND COALESCE("END_DATE", DATE '9999-12-31')
                THEN 1 ELSE 0
            END
        ) AS "active_2020_03_01",
        /* active on 31-Dec-2021 */
        SUM(
            CASE
                WHEN DATE '2021-12-31'
                     BETWEEN "START_DATE"
                     AND COALESCE("END_DATE", DATE '9999-12-31')
                THEN 1 ELSE 0
            END
        ) AS "active_2021_12_31"
    FROM FINANCE__ECONOMICS.CYBERSYN."FINANCIAL_BRANCH_ENTITIES"
    WHERE "STATE_ABBREVIATION" IS NOT NULL          -- keep U.S. state/territory rows
    GROUP BY "STATE_ABBREVIATION"
)

SELECT
    "STATE_ABBREVIATION",
    "active_2020_03_01",
    "active_2021_12_31",
    /* % change from 2020-03-01 to 2021-12-31 */
    CASE
        WHEN "active_2020_03_01" = 0 THEN NULL
        ELSE ROUND(
                 100.0 * ("active_2021_12_31" - "active_2020_03_01")
                 / "active_2020_03_01",
                 2
             )
    END AS "pct_change"
FROM state_counts
ORDER BY "pct_change" DESC NULLS LAST;