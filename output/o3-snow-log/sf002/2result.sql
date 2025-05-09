/* -----------------------------------------------------------
   Top 10 active U.S. banks (assets > $10 B) ranked by highest
   share of uninsured assets as of 2022-12-31
   -----------------------------------------------------------
*/
WITH assets_2022 AS (      -- total assets
    SELECT
        "ID_RSSD",
        "VALUE" AS "TOTAL_ASSETS"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES
    WHERE "VARIABLE" = 'ASSET'          -- Institutional Assets
      AND "DATE"     = '2022-12-31'
), insured_2022 AS (      -- % insured (estimated)
    SELECT
        "ID_RSSD",
        "VALUE" AS "INSURED_PCT"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES
    WHERE "VARIABLE" = 'ESTINS'         -- % Insured (Estimated)
      AND "DATE"     = '2022-12-31'
), combined AS (
    SELECT
        a."ID_RSSD",
        a."TOTAL_ASSETS",
        (1.0 - i."INSURED_PCT") AS "UNINSURED_PCT"
    FROM assets_2022 a
    JOIN insured_2022 i
      ON a."ID_RSSD" = i."ID_RSSD"
    WHERE a."TOTAL_ASSETS" > 10000000000      -- > $10 B
)
SELECT
    e."NAME"                         AS "BANK_NAME",
    c."UNINSURED_PCT"
FROM combined c
JOIN FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ENTITIES e
  ON c."ID_RSSD" = e."ID_RSSD"
WHERE e."CATEGORY"  = 'Bank'
  AND e."IS_ACTIVE" = TRUE
ORDER BY c."UNINSURED_PCT" DESC NULLS LAST
LIMIT 10;