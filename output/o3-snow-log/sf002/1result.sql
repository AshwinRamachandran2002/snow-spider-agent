/* Top-10 active U.S. banks (assets > $10 B) with the highest share of
   uninsured assets as of 2022-12-31 */

WITH insured_pct AS (  -- % Insured (Estimated)
    SELECT
        "ID_RSSD",
        MAX("VALUE") AS "INSURED_PCT"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES
    WHERE "DATE" = '2022-12-31'
      AND "VARIABLE_NAME" ILIKE '%Insured (Estimated)%'
    GROUP BY "ID_RSSD"
),
total_assets AS (      -- Total assets (Average Total Assets – ASSET5)
    SELECT
        "ID_RSSD",
        MAX("VALUE") AS "TOTAL_ASSETS_USD"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES
    WHERE "DATE" = '2022-12-31'
      AND "VARIABLE" = 'ASSET5'
    GROUP BY "ID_RSSD"
)

SELECT
    ent."NAME"                                      AS "BANK_NAME",
    ROUND((1 - ins."INSURED_PCT") * 100, 2)         AS "PCT_UNINSURED_ASSETS"
FROM insured_pct          ins
JOIN total_assets         ast  ON ast."ID_RSSD" = ins."ID_RSSD"
JOIN FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ENTITIES ent
     ON ent."ID_RSSD" = ins."ID_RSSD"
WHERE ent."CATEGORY"          = 'Bank'
  AND ent."IS_ACTIVE"         = TRUE
  AND ast."TOTAL_ASSETS_USD"  > 10000000000        -- > $10 B
  AND ins."INSURED_PCT" IS NOT NULL
ORDER BY "PCT_UNINSURED_ASSETS" DESC NULLS LAST
LIMIT 10;