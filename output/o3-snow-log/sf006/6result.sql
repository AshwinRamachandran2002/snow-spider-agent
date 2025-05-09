SELECT
    "STATE_ABBREVIATION"                                       AS "STATE",
    
    /* Branches active on 01-Mar-2020 */
    SUM(
        CASE 
            WHEN "START_DATE" <= DATE '2020-03-01'
             AND ( "END_DATE" IS NULL OR "END_DATE" >= DATE '2020-03-01')
            THEN 1 ELSE 0 
        END
    )                                                          AS "ACTIVE_2020_03_01",
    
    /* Branches active on 31-Dec-2021 */
    SUM(
        CASE 
            WHEN "START_DATE" <= DATE '2021-12-31'
             AND ( "END_DATE" IS NULL OR "END_DATE" >= DATE '2021-12-31')
            THEN 1 ELSE 0 
        END
    )                                                          AS "ACTIVE_2021_12_31",
    
    /* % change from 2020-03-01 to 2021-12-31 */
    CASE
        WHEN SUM(
                CASE 
                    WHEN "START_DATE" <= DATE '2020-03-01'
                     AND ( "END_DATE" IS NULL OR "END_DATE" >= DATE '2020-03-01')
                    THEN 1 ELSE 0 
                END
             ) = 0
        THEN NULL           /* avoid divide-by-zero */
        ELSE
            (
                SUM(
                    CASE 
                        WHEN "START_DATE" <= DATE '2021-12-31'
                         AND ( "END_DATE" IS NULL OR "END_DATE" >= DATE '2021-12-31')
                        THEN 1 ELSE 0 
                    END
                )
              - SUM(
                    CASE 
                        WHEN "START_DATE" <= DATE '2020-03-01'
                         AND ( "END_DATE" IS NULL OR "END_DATE" >= DATE '2020-03-01')
                        THEN 1 ELSE 0 
                    END
                )
            ) 
            / NULLIF(                       /* ensure non-zero divisor */
                SUM(
                    CASE 
                        WHEN "START_DATE" <= DATE '2020-03-01'
                         AND ( "END_DATE" IS NULL OR "END_DATE" >= DATE '2020-03-01')
                        THEN 1 ELSE 0 
                    END
                ) :: FLOAT , 0
            ) * 100
    END                                                      AS "PCT_CHANGE"
FROM
    "FINANCE__ECONOMICS"."CYBERSYN"."FINANCIAL_BRANCH_ENTITIES"
WHERE
    "CATEGORY" = 'Branch'            /* focus on branch-level entities */
GROUP BY
    "STATE_ABBREVIATION"
ORDER BY
    "STATE_ABBREVIATION";