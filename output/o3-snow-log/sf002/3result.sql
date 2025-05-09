/*  Top 10 active U.S. banks (assets > $10 B) ranked by highest % of uninsured deposits
    as of 2022-12-31 (computed as 1 – “% Insured (Estimated)” variable).            */

SELECT
    e."NAME"                                              AS "BANK_NAME",
    ROUND( (1 - i."VALUE") * 100 , 2 )                    AS "PCT_UNINSURED_ASSETS"
FROM  FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES   a      -- total assets
JOIN  FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES   i      -- % insured (estimated)
      ON  a."ID_RSSD" = i."ID_RSSD"
      AND i."DATE"    = '2022-12-31'
      AND i."VARIABLE"= 'ESTINS'                                          -- % Insured (Estimated)
JOIN  FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ENTITIES     e
      ON  e."ID_RSSD" = a."ID_RSSD"
WHERE a."DATE"     = '2022-12-31'
  AND a."VARIABLE" = 'ASSET'                                              -- total assets
  AND a."VALUE"   > 10000000000                                           -- > $10 B
  AND e."CATEGORY" = 'Bank'
  AND e."IS_ACTIVE" = TRUE                                                -- active banks only
ORDER BY (1 - i."VALUE") DESC NULLS LAST                                  -- highest uninsured %
LIMIT 10;