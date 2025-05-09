/* Top 10 active banks (assets > $10 B) ranked by highest % of uninsured assets
   as of the 2022‑Q4 Call Report (2022‑12‑31)                         */

WITH insured_pct AS (        -- % Insured (Estimated)
    SELECT  t."ID_RSSD",
            t."VALUE"  AS insured_pct
    FROM    FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES   t
    JOIN    FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ATTRIBUTES   a
           ON t."VARIABLE" = a."VARIABLE"
    WHERE   a."VARIABLE_NAME" ILIKE '%Insured (Estimated)%'
      AND   a."UNIT" ILIKE '%Percent%'          -- keep the percentage field
      AND   t."DATE" = '2022-12-31'
),

assets AS (                  -- total assets
    SELECT  "ID_RSSD",
            "VALUE" AS total_assets
    FROM    FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES
    WHERE   "VARIABLE" = 'ASSET'                -- Total Assets variable code
      AND   "DATE"     = '2022-12-31'
),

active_banks AS (            -- currently‑active banks in the entities file
    SELECT  "ID_RSSD",
            "NAME" AS bank_name
    FROM    FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ENTITIES
    WHERE   "CATEGORY"   = 'Bank'
      AND   "IS_ACTIVE"  = TRUE
)

SELECT  ab.bank_name,
        ROUND( (1 - ip.insured_pct) * 100 , 2)  AS uninsured_asset_percent
FROM        active_banks   ab
JOIN        insured_pct    ip  ON ab."ID_RSSD" = ip."ID_RSSD"
JOIN        assets         at  ON ab."ID_RSSD" = at."ID_RSSD"
WHERE       at.total_assets > 10000000000        -- > $10 B
ORDER BY    uninsured_asset_percent DESC NULLS LAST,
            ab.bank_name
LIMIT 10;