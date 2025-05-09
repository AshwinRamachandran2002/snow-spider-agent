WITH branch_status AS (
    SELECT
        "STATE_ABBREVIATION"                                                   AS "STATE",
        /* active on 1‑Mar‑2020 ? */
        IFF(
            "START_DATE" <= DATE '2020-03-01'
            AND ( "END_DATE" IS NULL OR "END_DATE" >= DATE '2020-03-01'),
            1, 0)                                                              AS "ACTIVE_2020_03_01",
        /* active on 31‑Dec‑2021 ? */
        IFF(
            "START_DATE" <= DATE '2021-12-31'
            AND ( "END_DATE" IS NULL OR "END_DATE" >= DATE '2021-12-31'),
            1, 0)                                                              AS "ACTIVE_2021_12_31"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_BRANCH_ENTITIES
    WHERE "STATE_ABBREVIATION" IS NOT NULL          -- keep rows with valid U.S. state codes
)

SELECT
    "STATE",
    SUM("ACTIVE_2020_03_01")                                                AS "ACTIVE_BRANCHES_2020_03_01",
    SUM("ACTIVE_2021_12_31")                                                AS "ACTIVE_BRANCHES_2021_12_31",
    ROUND(
          IFF(
              SUM("ACTIVE_2020_03_01") = 0,
              NULL,                                                         -- avoid division by zero
              ( (SUM("ACTIVE_2021_12_31") - SUM("ACTIVE_2020_03_01"))
                / SUM("ACTIVE_2020_03_01") ) * 100
          )
    , 2)                                                                    AS "PERCENT_CHANGE"
FROM branch_status
GROUP BY "STATE"
ORDER BY "STATE";