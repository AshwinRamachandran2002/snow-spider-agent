WITH
/*-----------------------------------------------------------------------
1.  Pull total assets for the 2022-12-31 Call Report (in USD)
------------------------------------------------------------------------*/
assets AS (
    SELECT
        "ID_RSSD",
        "VALUE" AS "ASSETS_USD"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES
    WHERE "VARIABLE" = 'ASSET'
      AND "DATE"     = '2022-12-31'
),
/*-----------------------------------------------------------------------
2.  Pull the bank-reported “% Insured (Estimated)” for the same date
------------------------------------------------------------------------*/
insured AS (
    SELECT
        "ID_RSSD",
        "VALUE" AS "PCT_INSURED"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES
    WHERE "VARIABLE" = 'ESTINS'
      AND "DATE"     = '2022-12-31'
),
/*-----------------------------------------------------------------------
3.  Keep currently-active banks only
------------------------------------------------------------------------*/
active_banks AS (
    SELECT
        "ID_RSSD",
        "NAME"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ENTITIES
    WHERE "CATEGORY"  = 'Bank'
      AND "IS_ACTIVE" = TRUE
)
/*-----------------------------------------------------------------------
4.  Assemble and rank
------------------------------------------------------------------------*/
SELECT
    b."NAME"                                                     AS "BANK_NAME",
    ROUND( (1 - i."PCT_INSURED") * 100 , 4 )                     AS "UNINSURED_ASSET_PCT"
FROM active_banks b
JOIN assets       a USING ("ID_RSSD")
JOIN insured      i USING ("ID_RSSD")
WHERE a."ASSETS_USD" > 10000000000          -- > $10 billion
  AND i."PCT_INSURED" IS NOT NULL
ORDER BY "UNINSURED_ASSET_PCT" DESC NULLS LAST
LIMIT 10;