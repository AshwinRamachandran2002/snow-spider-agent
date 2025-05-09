/*  Active U.S. financial branch entities on
    1) 2020-03-01
    2) 2021-12-31
    plus % change between the two dates                                    */

SELECT
    "ID_STATE"                         AS "GEO_ID_STATE",
    "STATE_ABBREVIATION"               AS "STATE",
    
    /* branches active on 1-Mar-2020 */
    COUNT(
        CASE
            WHEN "START_DATE" <= DATE '2020-03-01'
             AND ( "END_DATE" IS NULL OR "END_DATE" >= DATE '2020-03-01')
            THEN 1
        END
    )                                   AS "ACTIVE_2020_03_01",
    
    /* branches active on 31-Dec-2021 */
    COUNT(
        CASE
            WHEN "START_DATE" <= DATE '2021-12-31'
             AND ( "END_DATE" IS NULL OR "END_DATE" >= DATE '2021-12-31')
            THEN 1
        END
    )                                   AS "ACTIVE_2021_12_31",
    
    /* percent change (NULL when 2020 count = 0) */
    CASE
        WHEN COUNT(
                 CASE
                     WHEN "START_DATE" <= DATE '2020-03-01'
                      AND ( "END_DATE" IS NULL OR "END_DATE" >= DATE '2020-03-01')
                     THEN 1
                 END
             ) = 0
        THEN NULL
        ELSE
            (
              COUNT(
                  CASE
                      WHEN "START_DATE" <= DATE '2021-12-31'
                       AND ( "END_DATE" IS NULL OR "END_DATE" >= DATE '2021-12-31')
                      THEN 1
                  END
              )
              -
              COUNT(
                  CASE
                      WHEN "START_DATE" <= DATE '2020-03-01'
                       AND ( "END_DATE" IS NULL OR "END_DATE" >= DATE '2020-03-01')
                      THEN 1
                  END
              )
            )
            * 100.0
            /
            NULLIF(
                COUNT(
                    CASE
                        WHEN "START_DATE" <= DATE '2020-03-01'
                         AND ( "END_DATE" IS NULL OR "END_DATE" >= DATE '2020-03-01')
                        THEN 1
                    END
                ), 0
            )
    END                                 AS "PCT_CHANGE"
FROM
    "FINANCE__ECONOMICS"."CYBERSYN"."FINANCIAL_BRANCH_ENTITIES"
WHERE
    "ID_COUNTRY" = 'country/USA'         -- keep only U.S. branches
GROUP BY
    "ID_STATE",
    "STATE_ABBREVIATION"
ORDER BY
    "STATE_ABBREVIATION" NULLS LAST;