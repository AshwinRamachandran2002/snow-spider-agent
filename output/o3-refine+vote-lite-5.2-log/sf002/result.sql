/*-----------------------------------------------------------
Top 10 active U.S. banks (assets > $10 B) ranked by the
highest share of uninsured assets as of 2022‑12‑31.
Uninsured % = 1 – “% Insured (Estimated)”.
-----------------------------------------------------------*/
WITH
/* identify variable codes we need                                      */
insured_var AS (
    SELECT "VARIABLE" AS insured_variable
    FROM   FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ATTRIBUTES
    WHERE  UPPER("VARIABLE_NAME") LIKE '%INSURED (ESTIMATED)%'          -- e.g., “% Insured (Estimated)”
    LIMIT  1
),
assets_var AS (
    SELECT "VARIABLE" AS assets_variable
    FROM   FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ATTRIBUTES
    WHERE  UPPER("VARIABLE_NAME") LIKE 'TOTAL ASSETS%'                  -- e.g., “Total Assets”
    LIMIT  1
),

/* pull 2022‑Q4 insured‑percentage & asset totals                       */
insured_q4 AS (
    SELECT CAST(t."ID_RSSD" AS NUMBER)          AS id_rssd,
           CAST(t."VALUE"  AS FLOAT)            AS insured_pct
    FROM   FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES t
    JOIN   insured_var v
      ON   t."VARIABLE" = v.insured_variable
    WHERE  t."DATE" = '2022-12-31'
),
assets_q4 AS (
    SELECT CAST(t."ID_RSSD" AS NUMBER)          AS id_rssd,
           CAST(t."VALUE"  AS FLOAT)            AS assets_usd
    FROM   FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES t
    JOIN   assets_var a
      ON   t."VARIABLE" = a.assets_variable
    WHERE  t."DATE" = '2022-12-31'
),

/* combine with entity information & apply filters                      */
bank_stats AS (
    SELECT e."NAME"                             AS bank_name,
           i.insured_pct,
           a.assets_usd
    FROM   insured_q4 i
    JOIN   assets_q4  a  ON a.id_rssd = i.id_rssd
    JOIN   FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ENTITIES e
           ON e."ID_RSSD" = i.id_rssd
    WHERE  e."CATEGORY" = 'Bank'                -- keep banks only
      AND  e."IS_ACTIVE" = TRUE                 -- active institutions
      AND  a.assets_usd >= 10000000000          -- assets > $10 B
)

/* final ranking                                                         */
SELECT
       bank_name,
       ROUND((1 - insured_pct) * 100, 2) AS percent_uninsured_assets
FROM   bank_stats
ORDER  BY percent_uninsured_assets DESC NULLS LAST, bank_name
LIMIT  10;