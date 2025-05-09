/* -----------------------------------------------------------------------
Top 10 active U.S. banks by highest share of uninsured assets
( = 1 – “% Insured (Estimated)” ) on the 2022‑12‑31 Call‑Report date
------------------------------------------------------------------------ */

/* 1.  Identify the exact variable codes                              */
WITH
insured_var AS (          /* quarterly % Insured (Estimated) variable  */
    SELECT  "VARIABLE"
    FROM    FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ATTRIBUTES
    WHERE   LOWER("VARIABLE_NAME")      ILIKE '%insured (estimated)%'
      AND   LOWER("UNIT")              ILIKE '%percent%'
      AND   "FREQUENCY"                =    'Quarterly'
),
asset_var AS (            /* quarterly Total Assets variable           */
    SELECT  "VARIABLE"
    FROM    FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ATTRIBUTES
    WHERE   LOWER("VARIABLE_NAME")      ILIKE '%total assets%'
      AND   LOWER("UNIT")              ILIKE '%usd%'
      AND   "FREQUENCY"                =    'Quarterly'
)

/* 2.  Pull 2022‑Q4 observations for the two variables                */
SELECT
        ent."NAME"                                          AS "BANK_NAME",
        (1 - ins."VALUE")                                   AS "UNINSURED_ASSETS_PERCENT"
FROM
        insured_var  iv
JOIN    FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES   ins
          ON  ins."VARIABLE"   = iv."VARIABLE"
          AND ins."DATE"       = '2022-12-31'

JOIN    asset_var   av
JOIN    FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES   ast
          ON  ast."VARIABLE"   = av."VARIABLE"
          AND ast."ID_RSSD"    = ins."ID_RSSD"
          AND ast."DATE"       = '2022-12-31'

JOIN    FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ENTITIES     ent
          ON  ent."ID_RSSD"    = ins."ID_RSSD"

WHERE   ent."IS_ACTIVE"              =  TRUE           -- currently‑active banks
  AND   ent."CATEGORY"               = 'Bank'
  AND   ast."VALUE"                  >= 10000000000    -- assets > $10 billion

ORDER BY
        "UNINSURED_ASSETS_PERCENT"   DESC NULLS LAST,
        ent."NAME"
LIMIT 10;