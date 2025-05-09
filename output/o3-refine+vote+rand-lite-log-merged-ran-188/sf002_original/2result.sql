WITH insured_pct AS (
    /* estimated percentage of a bank’s assets that are FDIC–insured */
    SELECT
        t."ID_RSSD",
        t."VALUE"                           AS insured_ratio,   -- expressed 0‑1
        t."DATE"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES t
    JOIN FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ATTRIBUTES a
          ON t."VARIABLE" = a."VARIABLE"
    WHERE a."VARIABLE_NAME" ILIKE '%Insured%Estimated%'          -- "% Insured (Estimated)"
      AND t."DATE" = '2022-12-31'
), assets_q4_2022 AS (
    /* total assets on the same Call‑Report date */
    SELECT
        t."ID_RSSD",
        t."VALUE"                           AS total_assets_usd,
        t."DATE"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES t
    JOIN FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ATTRIBUTES a
          ON t."VARIABLE" = a."VARIABLE"
    WHERE a."VARIABLE_NAME" ILIKE '%Total Assets%'               -- total assets, USD
      AND a."UNIT" = 'USD'
      AND t."DATE" = '2022-12-31'
), active_banks AS (
    /* restrict to currently‑active chartered banks */
    SELECT
        e."ID_RSSD",
        e."NAME"                              AS bank_name
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ENTITIES e
    WHERE e."CATEGORY" = 'Bank'
      AND e."IS_ACTIVE" = TRUE
)
SELECT
    ab.bank_name,
    ROUND((1 - ip.insured_ratio) * 100, 2)     AS uninsured_asset_percent
FROM active_banks            ab
JOIN insured_pct             ip  ON ab."ID_RSSD" = ip."ID_RSSD"
JOIN assets_q4_2022          at  ON ab."ID_RSSD" = at."ID_RSSD"
WHERE at.total_assets_usd > 10000000000         -- > $10 billion
ORDER BY uninsured_asset_percent DESC NULLS LAST
LIMIT 10;