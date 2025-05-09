SELECT
    "STATE_ABBREVIATION"                                           AS "STATE",
    SUM(
        CASE
            WHEN "START_DATE" <= '2020-03-01'
             AND ( "END_DATE" IS NULL OR "END_DATE" >= '2020-03-01' )
            THEN 1 ELSE 0
        END
    )                                                              AS "ACTIVE_2020_03_01",
    SUM(
        CASE
            WHEN "START_DATE" <= '2021-12-31'
             AND ( "END_DATE" IS NULL OR "END_DATE" >= '2021-12-31' )
            THEN 1 ELSE 0
        END
    )                                                              AS "ACTIVE_2021_12_31",
    CASE
        WHEN SUM(
                 CASE
                     WHEN "START_DATE" <= '2020-03-01'
                      AND ( "END_DATE" IS NULL OR "END_DATE" >= '2020-03-01' )
                     THEN 1 ELSE 0
                 END
             ) = 0
        THEN NULL
        ELSE ROUND(
                 (
                     SUM(
                         CASE
                             WHEN "START_DATE" <= '2021-12-31'
                              AND ( "END_DATE" IS NULL OR "END_DATE" >= '2021-12-31' )
                             THEN 1 ELSE 0
                         END
                     )
                     - SUM(
                         CASE
                             WHEN "START_DATE" <= '2020-03-01'
                              AND ( "END_DATE" IS NULL OR "END_DATE" >= '2020-03-01' )
                             THEN 1 ELSE 0
                         END
                     )
                 ) * 100.0
                 / SUM(
                       CASE
                           WHEN "START_DATE" <= '2020-03-01'
                            AND ( "END_DATE" IS NULL OR "END_DATE" >= '2020-03-01' )
                           THEN 1 ELSE 0
                       END
                   )
                 , 4
             )
    END                                                           AS "PERCENT_CHANGE"
FROM
    "FINANCE__ECONOMICS"."CYBERSYN"."FINANCIAL_BRANCH_ENTITIES"
WHERE
    "ID_COUNTRY" = 'country/USA'
    AND "STATE_ABBREVIATION" IS NOT NULL
GROUP BY
    "STATE_ABBREVIATION"
ORDER BY
    "STATE_ABBREVIATION";