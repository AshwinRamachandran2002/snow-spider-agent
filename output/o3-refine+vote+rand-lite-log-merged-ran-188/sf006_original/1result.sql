/*  Active financial branch entities by U.S. state
    – counts on 2020‑03‑01 vs 2021‑12‑31
    – percentage change between the two dates                                       */

WITH branch_states AS (
    SELECT
        "ID_RSSD",
        "STATE_ABBREVIATION",
        CAST("START_DATE" AS DATE)   AS start_date,
        CAST("END_DATE"   AS DATE)   AS end_date
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_BRANCH_ENTITIES
    WHERE "STATE_ABBREVIATION" IS NOT NULL
),

state_counts AS (
    SELECT
        "STATE_ABBREVIATION",
        /* active on 1‑Mar‑2020 */
        COUNT(DISTINCT CASE
                           WHEN start_date <= '2020-03-01'
                                AND (end_date IS NULL OR end_date >= '2020-03-01')
                           THEN "ID_RSSD"
                       END) AS active_2020_03_01,

        /* active on 31‑Dec‑2021 */
        COUNT(DISTINCT CASE
                           WHEN start_date <= '2021-12-31'
                                AND (end_date IS NULL OR end_date >= '2021-12-31')
                           THEN "ID_RSSD"
                       END) AS active_2021_12_31
    FROM branch_states
    GROUP BY "STATE_ABBREVIATION"
)

SELECT
    "STATE_ABBREVIATION"                            AS "STATE",
    active_2020_03_01                               AS "ACTIVE_2020_03_01",
    active_2021_12_31                               AS "ACTIVE_2021_12_31",
    ROUND(
        (active_2021_12_31 - active_2020_03_01)
        * 100.0 / NULLIF(active_2020_03_01, 0), 2
    )                                               AS "PCT_CHANGE"
FROM state_counts
ORDER BY "STATE";