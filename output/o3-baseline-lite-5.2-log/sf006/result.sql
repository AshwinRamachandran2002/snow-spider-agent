WITH cnt_2020 AS (   -- branches active on 2020‑03‑01
    SELECT
        "ID_STATE"                AS state_id,
        "STATE_ABBREVIATION"      AS state_abbr,
        COUNT(*)                  AS active_2020
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_BRANCH_ENTITIES
    WHERE "CATEGORY" = 'Branch'
      AND "ID_COUNTRY" = 'country/USA'
      AND "START_DATE" <= DATE '2020-03-01'
      AND ( "END_DATE" IS NULL OR "END_DATE" >= DATE '2020-03-01')
    GROUP BY state_id, state_abbr
),
cnt_2021 AS (   -- branches active on 2021‑12‑31
    SELECT
        "ID_STATE"                AS state_id,
        "STATE_ABBREVIATION"      AS state_abbr,
        COUNT(*)                  AS active_2021
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_BRANCH_ENTITIES
    WHERE "CATEGORY" = 'Branch'
      AND "ID_COUNTRY" = 'country/USA'
      AND "START_DATE" <= DATE '2021-12-31'
      AND ( "END_DATE" IS NULL OR "END_DATE" >= DATE '2021-12-31')
    GROUP BY state_id, state_abbr
),
combined AS (  -- merge the two counts
    SELECT
        COALESCE(c20.state_id,  c21.state_id)  AS state_id,
        COALESCE(c20.state_abbr, c21.state_abbr) AS state_abbr,
        COALESCE(c20.active_2020, 0)           AS active_2020,
        COALESCE(c21.active_2021, 0)           AS active_2021
    FROM cnt_2020 c20
    FULL OUTER JOIN cnt_2021 c21
           ON c20.state_id = c21.state_id
)
SELECT
    state_abbr                                         AS "STATE",
    active_2020                                        AS "ACTIVE_ENTITIES_2020_03_01",
    active_2021                                        AS "ACTIVE_ENTITIES_2021_12_31",
    CASE
        WHEN active_2020 = 0 THEN NULL
        ELSE ROUND( (active_2021 - active_2020) * 100.0 / active_2020 , 2)
    END                                                AS "PERCENT_CHANGE"
FROM combined
ORDER BY state_abbr;