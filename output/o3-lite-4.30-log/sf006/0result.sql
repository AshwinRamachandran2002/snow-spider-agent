WITH march_2020 AS (
    SELECT 
        "STATE_ABBREVIATION"                      AS state,
        COUNT(DISTINCT "ID_RSSD")                 AS active_2020_03_01
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_BRANCH_ENTITIES
    WHERE "CATEGORY"   = 'Branch'
      AND "ID_COUNTRY" = 'country/USA'
      AND "START_DATE" <= '2020-03-01'
      AND ("END_DATE" IS NULL OR "END_DATE" >= '2020-03-01')
    GROUP BY "STATE_ABBREVIATION"
),
dec_2021 AS (
    SELECT 
        "STATE_ABBREVIATION"                      AS state,
        COUNT(DISTINCT "ID_RSSD")                 AS active_2021_12_31
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_BRANCH_ENTITIES
    WHERE "CATEGORY"   = 'Branch'
      AND "ID_COUNTRY" = 'country/USA'
      AND "START_DATE" <= '2021-12-31'
      AND ("END_DATE" IS NULL OR "END_DATE" >= '2021-12-31')
    GROUP BY "STATE_ABBREVIATION"
)
SELECT
    COALESCE(m.state, d.state)                                AS state,
    COALESCE(m.active_2020_03_01, 0)                          AS active_2020_03_01,
    COALESCE(d.active_2021_12_31, 0)                          AS active_2021_12_31,
    ROUND(
        100.0 * (COALESCE(d.active_2021_12_31, 0) - COALESCE(m.active_2020_03_01, 0))
        / NULLIF(COALESCE(m.active_2020_03_01, 0), 0),
        4
    )                                                         AS percent_change
FROM march_2020 m
FULL JOIN dec_2021 d USING (state)
ORDER BY state;