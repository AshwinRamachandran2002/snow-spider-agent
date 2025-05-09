WITH active_counts AS (
    -- Entities active on 01-Mar-2020
    SELECT
        "STATE_ABBREVIATION"                                     AS state,
        DATE '2020-03-01'                                         AS ref_date,
        COUNT(*)                                                  AS active_cnt
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_BRANCH_ENTITIES
    WHERE "START_DATE" <= DATE '2020-03-01'
      AND ( "END_DATE" IS NULL OR "END_DATE" >= DATE '2020-03-01' )
    GROUP BY "STATE_ABBREVIATION"

    UNION ALL

    -- Entities active on 31-Dec-2021
    SELECT
        "STATE_ABBREVIATION"                                     AS state,
        DATE '2021-12-31'                                         AS ref_date,
        COUNT(*)                                                  AS active_cnt
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_BRANCH_ENTITIES
    WHERE "START_DATE" <= DATE '2021-12-31'
      AND ( "END_DATE" IS NULL OR "END_DATE" >= DATE '2021-12-31' )
    GROUP BY "STATE_ABBREVIATION"
)

SELECT
    state,
    MAX(CASE WHEN ref_date = DATE '2020-03-01' THEN active_cnt END) AS active_2020_03_01,
    MAX(CASE WHEN ref_date = DATE '2021-12-31' THEN active_cnt END) AS active_2021_12_31,
    CASE
        WHEN MAX(CASE WHEN ref_date = DATE '2020-03-01' THEN active_cnt END) = 0 THEN NULL
        ELSE ROUND(
                ( MAX(CASE WHEN ref_date = DATE '2021-12-31' THEN active_cnt END)
                - MAX(CASE WHEN ref_date = DATE '2020-03-01' THEN active_cnt END) )
                * 100.0
                / MAX(CASE WHEN ref_date = DATE '2020-03-01' THEN active_cnt END)
            , 2)
    END                                                          AS pct_change
FROM active_counts
GROUP BY state
ORDER BY state;