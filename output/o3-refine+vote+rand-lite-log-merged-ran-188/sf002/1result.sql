SELECT
    e."NAME"                                                        AS "BANK_NAME",
    ROUND((1 - ins."VALUE") * 100 , 2)                              AS "UNINSURED_ASSET_PCT"
FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES  ta            -- total assets
JOIN FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES  ins           -- % insured (estimated)
      ON  ta."ID_RSSD" = ins."ID_RSSD"
      AND ta."DATE"    = ins."DATE"
JOIN FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ENTITIES    e
      ON ta."ID_RSSD" = e."ID_RSSD"
WHERE ta."DATE"       = '2022-12-31'          -- quarter-end reference date
  AND ta."VARIABLE"   = 'ASSET'               -- total assets
  AND ins."VARIABLE"  = 'ESTINSR'             -- % insured (estimated)
  AND e."IS_ACTIVE"   = TRUE                  -- active institutions
  AND ta."VALUE"      > 10000000000           -- assets > $10 billion
  AND ins."VALUE"     IS NOT NULL             -- ensure insured % available
ORDER BY (1 - ins."VALUE") DESC NULLS LAST    -- highest uninsured %
LIMIT 10;