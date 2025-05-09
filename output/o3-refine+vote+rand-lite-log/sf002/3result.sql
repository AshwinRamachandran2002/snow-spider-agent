/* Top 10 active banks (assets > $10B) with the largest share of uninsured assets
   as of 2022‑12‑31 (Q4‑2022) */

WITH insured_var AS (          -- variable that holds “% Insured (Estimated)”
    SELECT "VARIABLE"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ATTRIBUTES
    WHERE "VARIABLE_NAME" ILIKE '%Insured (Estimated)%'
    LIMIT 1
),
asset_var AS (                 -- variable that holds total assets
    SELECT "VARIABLE"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ATTRIBUTES
    WHERE "VARIABLE_NAME" ILIKE '%total assets%'
    LIMIT 1
),

/* latest‑quarter insured‑deposit percentage */
insured AS (
    SELECT "ID_RSSD"::NUMBER                  AS id_rssd,
           "VALUE"                            AS pct_insured          -- may be 0‑1 or 0‑100
    FROM   FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES
    WHERE  "VARIABLE" = (SELECT "VARIABLE" FROM insured_var)
      AND  "DATE"     = '2022-12-31'
),

/* latest‑quarter total assets */
assets AS (
    SELECT "ID_RSSD"::NUMBER                  AS id_rssd,
           "VALUE"                            AS total_assets_usd
    FROM   FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES
    WHERE  "VARIABLE" = (SELECT "VARIABLE" FROM asset_var)
      AND  "DATE"     = '2022-12-31'
),

/* combine, filter to active banks > $10 B, compute uninsured %  */
calc AS (
    SELECT e."NAME"                                            AS bank_name,
           a.total_assets_usd,
           /* if pct_insured is already 0‑1 keep it, if 0‑100 convert */
           100 * (CASE WHEN i.pct_insured > 1
                       THEN 1 - i.pct_insured / 100
                       ELSE 1 - i.pct_insured
                  END)                                         AS pct_uninsured
    FROM   assets a
    JOIN   insured i  ON a.id_rssd = i.id_rssd
    JOIN   FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ENTITIES e
           ON e."ID_RSSD" = a.id_rssd
    WHERE  e."CATEGORY"  = 'Bank'
      AND  e."IS_ACTIVE" = TRUE
      AND  a.total_assets_usd > 10000000000   -- $10 B
)

/* final ranking */
SELECT bank_name,
       pct_uninsured
FROM   calc
ORDER  BY pct_uninsured DESC NULLS LAST,
          bank_name
LIMIT 10;