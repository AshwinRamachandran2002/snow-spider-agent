SELECT
    "ID_STATE"                                              AS "STATE_GEO_ID",
    SUM(
        CASE
            WHEN "START_DATE" <= DATE '2020-03-01'
                 AND ( "END_DATE" IS NULL OR "END_DATE" >= DATE '2020-03-01')
            THEN 1 ELSE 0
        END
    )                                                       AS "ACTIVE_COUNT_2020_03_01",
    SUM(
        CASE
            WHEN "START_DATE" <= DATE '2021-12-31'
                 AND ( "END_DATE" IS NULL OR "END_DATE" >= DATE '2021-12-31')
            THEN 1 ELSE 0
        END
    )                                                       AS "ACTIVE_COUNT_2021_12_31",
    CASE
        WHEN SUM(
                 CASE
                     WHEN "START_DATE" <= DATE '2020-03-01'
                          AND ( "END_DATE" IS NULL OR "END_DATE" >= DATE '2020-03-01')
                     THEN 1 ELSE 0
                 END
             ) = 0
        THEN NULL
        ELSE
            ROUND(
                100.0
                * (
                    SUM(
                        CASE
                            WHEN "START_DATE" <= DATE '2021-12-31'
                                 AND ( "END_DATE" IS NULL OR "END_DATE" >= DATE '2021-12-31')
                            THEN 1 ELSE 0
                        END
                    )
                    -
                    SUM(
                        CASE
                            WHEN "START_DATE" <= DATE '2020-03-01'
                                 AND ( "END_DATE" IS NULL OR "END_DATE" >= DATE '2020-03-01')
                            THEN 1 ELSE 0
                        END
                    )
                  )
                /
                NULLIF(
                    SUM(
                        CASE
                            WHEN "START_DATE" <= DATE '2020-03-01'
                                 AND ( "END_DATE" IS NULL OR "END_DATE" >= DATE '2020-03-01')
                            THEN 1 ELSE 0
                        END
                    ), 0
                )
            , 4)
    END                                                     AS "PERCENT_CHANGE_2020_TO_2021"
FROM
    FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_BRANCH_ENTITIES
WHERE
    "CATEGORY"   = 'Branch'          -- focus on branch-level entities
    AND "ID_COUNTRY" = 'country/USA' -- limit to U.S. entities
GROUP BY
    "ID_STATE"
ORDER BY
    "STATE_GEO_ID";