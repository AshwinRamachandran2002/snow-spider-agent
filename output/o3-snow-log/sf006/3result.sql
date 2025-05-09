SELECT
    "STATE_ABBREVIATION"                                   AS "STATE",
    
    /* Branches active on 01-Mar-2020 */
    SUM(
        CASE 
            WHEN "START_DATE" <= DATE '2020-03-01'
             AND ("END_DATE" IS NULL OR "END_DATE" >= DATE '2020-03-01')
            THEN 1 ELSE 0 
        END
    )                                                      AS "ACTIVE_ON_2020_03_01",
    
    /* Branches active on 31-Dec-2021 */
    SUM(
        CASE 
            WHEN "START_DATE" <= DATE '2021-12-31'
             AND ("END_DATE" IS NULL OR "END_DATE" >= DATE '2021-12-31')
            THEN 1 ELSE 0 
        END
    )                                                      AS "ACTIVE_ON_2021_12_31",
    
    /* % change from 2020-03-01 to 2021-12-31 (NULL when 2020 base = 0) */
    ROUND(
        100.0 *
        (
            SUM(
                CASE 
                    WHEN "START_DATE" <= DATE '2021-12-31'
                     AND ("END_DATE" IS NULL OR "END_DATE" >= DATE '2021-12-31')
                    THEN 1 ELSE 0 
                END
            )
          - SUM(
                CASE 
                    WHEN "START_DATE" <= DATE '2020-03-01'
                     AND ("END_DATE" IS NULL OR "END_DATE" >= DATE '2020-03-01')
                    THEN 1 ELSE 0 
                END
            )
        )
        / NULLIF(
              SUM(
                  CASE 
                      WHEN "START_DATE" <= DATE '2020-03-01'
                       AND ("END_DATE" IS NULL OR "END_DATE" >= DATE '2020-03-01')
                      THEN 1 ELSE 0 
                  END
              ),
              0
          )
    , 4)                                                   AS "PCT_CHANGE_2020_TO_2021"
FROM FINANCE__ECONOMICS.CYBERSYN."FINANCIAL_BRANCH_ENTITIES"
WHERE
    "CATEGORY"      = 'Branch'            -- keep only branch entities
    AND "ID_COUNTRY" = 'country/USA'      -- restrict to U.S. locations
GROUP BY
    "STATE_ABBREVIATION"
ORDER BY
    "STATE_ABBREVIATION";