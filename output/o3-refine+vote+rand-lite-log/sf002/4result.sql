/* Top‑10 active banks (as of 2022‑12‑31) with > $10 B in assets,
   ranked by highest share of uninsured assets                     */
WITH insured_var AS (                       -- variable for “% Insured (Estimated)”
    SELECT "VARIABLE"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ATTRIBUTES
    WHERE "VARIABLE_NAME" ILIKE '%Insured (Estimated)%'
),
asset_var AS (                              -- variable for “Total Assets”
    SELECT "VARIABLE"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ATTRIBUTES
    WHERE "VARIABLE_NAME" ILIKE '%Total Assets%'
),

/* ---- pull 2022‑12‑31 values ---- */
insured_q4_22 AS (
    SELECT ts."ID_RSSD",
           ts."VALUE" AS insured_pct_raw               -- reported % insured
    FROM   FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES ts
    JOIN   insured_var v
           ON ts."VARIABLE" = v."VARIABLE"
    WHERE  ts."DATE" = '2022-12-31'
),
assets_q4_22 AS (
    SELECT ts."ID_RSSD",
           ts."VALUE" AS total_assets_usd
    FROM   FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES ts
    JOIN   asset_var v
           ON ts."VARIABLE" = v."VARIABLE"
    WHERE  ts."DATE" = '2022-12-31'
),

/* ---- combine & compute uninsured % ---- */
calc AS (
    SELECT a."ID_RSSD",
           a.total_assets_usd,
           i.insured_pct_raw,
           /* If value >1 treat as percentage, else already ratio; then compute uninsured % */
           100 * (1 - CASE WHEN i.insured_pct_raw > 1
                           THEN i.insured_pct_raw / 100
                           ELSE i.insured_pct_raw
                      END)      AS uninsured_pct
    FROM   assets_q4_22 a
    JOIN   insured_q4_22 i USING ("ID_RSSD")
    WHERE  a.total_assets_usd > 10000000000              -- > $10 B
),

/* ---- attach entity names & keep only active institutions ---- */
active_banks AS (
    SELECT e."NAME"                              AS bank_name,
           ROUND(c.uninsured_pct, 2)             AS percent_uninsured
    FROM   calc c
    JOIN   FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ENTITIES e
           ON e."ID_RSSD" = c."ID_RSSD"
    WHERE  e."IS_ACTIVE" = TRUE
)

SELECT bank_name,
       percent_uninsured
FROM   active_banks
ORDER  BY percent_uninsured DESC NULLS LAST,
          bank_name
LIMIT  10;