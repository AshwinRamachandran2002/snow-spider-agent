WITH insured_pct AS (   -- % of assets that are FDIC‑insured (estimated)
    SELECT 
        fit."ID_RSSD",
        AVG(CASE
                WHEN fit."UNIT" ILIKE '%percent%' THEN fit."VALUE" / 100.0
                ELSE fit."VALUE"
            END)                              AS "PCT_INSURED"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES fit
    WHERE fit."DATE" = '2022-12-31'
      AND ( fit."VARIABLE_NAME" ILIKE '%Insured (Estimated)%'
            OR fit."VARIABLE"      ILIKE 'PCTINS%' )
    GROUP BY fit."ID_RSSD"
),
total_assets AS (     -- total assets on the same call‑report date
    SELECT
        fit."ID_RSSD",
        MAX(fit."VALUE")                   AS "TOTAL_ASSETS_USD"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES fit
    WHERE fit."DATE" = '2022-12-31'
      AND ( fit."VARIABLE_NAME" ILIKE '%Total Assets%'
            OR fit."VARIABLE"      ILIKE 'ASSET%' )
    GROUP BY fit."ID_RSSD"
),
active_banks AS (     -- keep only currently‑active banks
    SELECT
        fie."ID_RSSD",
        fie."NAME" AS "BANK_NAME"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ENTITIES fie
    WHERE fie."CATEGORY"  = 'Bank'
      AND fie."IS_ACTIVE" = TRUE
)
SELECT
    ab."BANK_NAME",
    ROUND((1 - ip."PCT_INSURED") * 100, 2) AS "PCT_UNINSURED_ASSETS"
FROM active_banks  ab
JOIN insured_pct   ip ON ab."ID_RSSD" = ip."ID_RSSD"
JOIN total_assets  ta ON ab."ID_RSSD" = ta."ID_RSSD"
WHERE ta."TOTAL_ASSETS_USD" > 10000000000      -- assets > $10 billion
ORDER BY "PCT_UNINSURED_ASSETS" DESC NULLS LAST,
         ab."BANK_NAME"
LIMIT 10;