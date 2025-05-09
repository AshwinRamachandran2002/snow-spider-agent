WITH insured_pct AS (
    SELECT
        "ID_RSSD",
        "VALUE" AS "INSURED_SHARE"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES
    WHERE "DATE" = '2022-12-31'
      AND LOWER("VARIABLE_NAME") LIKE '%insured%'
      AND LOWER("VARIABLE_NAME") LIKE '%estimated%'
),
total_assets AS (
    SELECT
        "ID_RSSD",
        "VALUE" AS "TOTAL_ASSETS_USD"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES
    WHERE "DATE" = '2022-12-31'
      AND (
            "VARIABLE" = 'ASSET' 
         OR LOWER("VARIABLE_NAME") LIKE '%total assets%'
      )
),
eligible_banks AS (
    SELECT
        e."ID_RSSD",
        e."NAME"                           AS "BANK_NAME",
        a."TOTAL_ASSETS_USD",
        i."INSURED_SHARE"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ENTITIES   e
    JOIN total_assets a ON a."ID_RSSD" = e."ID_RSSD"
    JOIN insured_pct   i ON i."ID_RSSD" = e."ID_RSSD"
    WHERE e."CATEGORY"   = 'Bank'
      AND e."IS_ACTIVE"  = TRUE
      AND a."TOTAL_ASSETS_USD" > 10000000000             -- > $10 billion
)
SELECT
    "BANK_NAME",
    ROUND( (1 - "INSURED_SHARE") * 100 , 2)  AS "UNINSURED_ASSETS_PERCENT"
FROM eligible_banks
ORDER BY (1 - "INSURED_SHARE") DESC NULLS LAST
LIMIT 10;