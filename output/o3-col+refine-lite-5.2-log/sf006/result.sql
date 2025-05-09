/*  State‑level change in the number of active financial‑branch entities
    between 1‑Mar‑2020 and 31‑Dec‑2021                                    */

WITH base AS (   -- keep only rows that have a U.S. state code
    SELECT 
        "STATE_ABBREVIATION",
        "START_DATE",
        "END_DATE"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_BRANCH_ENTITIES
    WHERE "STATE_ABBREVIATION" IS NOT NULL
),

-- branches active on 1‑Mar‑2020
cte_2020 AS (
    SELECT
        "STATE_ABBREVIATION",
        COUNT(*)            AS "cnt_2020"
    FROM base
    WHERE "START_DATE" <= '2020-03-01'
      AND ( "END_DATE" IS NULL OR "END_DATE" >= '2020-03-01')
    GROUP BY "STATE_ABBREVIATION"
),

-- branches active on 31‑Dec‑2021
cte_2021 AS (
    SELECT
        "STATE_ABBREVIATION",
        COUNT(*)            AS "cnt_2021"
    FROM base
    WHERE "START_DATE" <= '2021-12-31'
      AND ( "END_DATE" IS NULL OR "END_DATE" >= '2021-12-31')
    GROUP BY "STATE_ABBREVIATION"
)

SELECT
    COALESCE(c20."STATE_ABBREVIATION", c21."STATE_ABBREVIATION")            AS "STATE_ABBREVIATION",
    c20."cnt_2020"                                                          AS "ACTIVE_BRANCHES_2020_03_01",
    c21."cnt_2021"                                                          AS "ACTIVE_BRANCHES_2021_12_31",
    ROUND(
        (c21."cnt_2021" - c20."cnt_2020") * 100.0 / NULLIF(c20."cnt_2020",0),
        2
    )                                                                       AS "PCT_CHANGE"
FROM cte_2020 c20
FULL JOIN cte_2021 c21
       ON c20."STATE_ABBREVIATION" = c21."STATE_ABBREVIATION"
ORDER BY "STATE_ABBREVIATION";