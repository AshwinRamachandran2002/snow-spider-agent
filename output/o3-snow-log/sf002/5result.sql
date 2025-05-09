/*  Top 10 active U.S. banks (assets > $10 B) ranked by highest share of
    uninsured assets as of the 2022-12-31 call-report quarter.                */

WITH active_banks AS (
    SELECT 
        "ID_RSSD",
        "NAME"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ENTITIES
    WHERE "CATEGORY"  = 'Bank'
      AND "IS_ACTIVE" = TRUE
),

/* ── total assets (USD) ──────────────────────────────────────────────────── */
total_assets AS (
    SELECT 
        ts."ID_RSSD",
        ts."VALUE" AS "TOTAL_ASSETS_USD"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES  ts
    JOIN FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ATTRIBUTES  a
      ON ts."VARIABLE" = a."VARIABLE"
    WHERE ts."DATE" = '2022-12-31'
      AND a."VARIABLE_NAME" ILIKE '%total%'
      AND a."VARIABLE_NAME" ILIKE '%asset%'
),

/* ── % insured (estimated) expressed as ratio-to-assets ─────────────────── */
insured_ratio AS (
    SELECT 
        ts."ID_RSSD",
        ts."VALUE" AS "PCT_INSURED"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES  ts
    JOIN FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ATTRIBUTES  a
      ON ts."VARIABLE" = a."VARIABLE"
    WHERE ts."DATE" = '2022-12-31'
      AND a."VARIABLE_NAME" ILIKE '%insured%'
      AND a."VARIABLE_NAME" ILIKE '%asset%'         -- ensures asset-based ratio
)

/* ── combine & rank ─────────────────────────────────────────────────────── */
SELECT 
    ab."NAME"                                            AS "BANK_NAME",
    ROUND( (1 - ir."PCT_INSURED") * 100 , 2 )            AS "PCT_UNINSURED"
FROM       active_banks  ab
INNER JOIN total_assets  ta  ON ta."ID_RSSD" = ab."ID_RSSD"
INNER JOIN insured_ratio ir  ON ir."ID_RSSD" = ab."ID_RSSD"
WHERE ta."TOTAL_ASSETS_USD" > 10000000000               -- > $10 B
ORDER BY "PCT_UNINSURED" DESC NULLS LAST
LIMIT 10;