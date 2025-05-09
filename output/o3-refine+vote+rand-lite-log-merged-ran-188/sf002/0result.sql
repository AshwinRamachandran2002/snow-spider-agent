/*  Top-10 active U.S. banks (assets > $10 B) ranked by highest share of uninsured assets
    on the 2022-12-31 Call Report date                                    */

WITH pct_insured AS (   -- “% Insured (Estimated)”
    SELECT
        t."ID_RSSD",
        CAST(t."VALUE" AS FLOAT)          AS "pct_insured"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES t
    WHERE t."DATE"    = '2022-12-31'
      AND t."VARIABLE" = 'ESTINS'         -- % Insured (Estimated)
),
total_assets AS (        -- Total assets
    SELECT
        t."ID_RSSD",
        CAST(t."VALUE" AS FLOAT)          AS "total_assets"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES t
    WHERE t."DATE"    = '2022-12-31'
      AND t."VARIABLE" = 'ASSET'          -- Total Assets
)

SELECT
       e."NAME"                                           AS "Bank Name",
       ROUND((1 - i."pct_insured") * 100, 2)              AS "Percent Uninsured Assets"
FROM   pct_insured      i
JOIN   total_assets     a  ON a."ID_RSSD" = i."ID_RSSD"
JOIN   FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ENTITIES e
       ON e."ID_RSSD" = i."ID_RSSD"
WHERE  e."IS_ACTIVE"         = TRUE              -- active institutions only
  AND  a."total_assets"      > 10000000000       -- assets > $10 B
  AND  i."pct_insured"       IS NOT NULL
ORDER  BY (1 - i."pct_insured") DESC NULLS LAST  -- highest uninsured share first
LIMIT 10;