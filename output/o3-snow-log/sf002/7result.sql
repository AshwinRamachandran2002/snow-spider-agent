/*  Top 10 active banks (assets > $10 B) with the highest share of uninsured assets
    as of 2022-12-31  */

SELECT
    e."NAME"                                                   AS "BANK_NAME",
    ROUND(1 - i."VALUE", 4)                                    AS "PCT_UNINSURED_ASSETS"
FROM   FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ENTITIES   e
JOIN   FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES a
       ON  a."ID_RSSD"  = TO_CHAR(e."ID_RSSD")
       AND a."VARIABLE" = 'ASSET'
       AND a."DATE"     = '2022-12-31'
JOIN   FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES i
       ON  i."ID_RSSD"  = a."ID_RSSD"
       AND i."VARIABLE" = 'ESTINS'          -- % Insured (Estimated)
       AND i."DATE"     = '2022-12-31'
WHERE  e."IS_ACTIVE"      = TRUE            -- active institutions
  AND  a."VALUE"          > 10000000000     -- assets > $10 B
  AND  i."VALUE"          IS NOT NULL       -- need insured-% data
ORDER BY (1 - i."VALUE") DESC NULLS LAST    -- rank by % uninsured
LIMIT 10;