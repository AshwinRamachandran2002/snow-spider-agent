WITH pivoted AS (   -- put assets and quarterly “% Insured (Estimated)” on one row
    SELECT
        t."ID_RSSD",
        MAX(CASE WHEN t."VARIABLE" = 'ASSET'    THEN t."VALUE" END) AS assets_usd,
        MAX(CASE WHEN t."VARIABLE" = 'IDDEPINR' THEN t."VALUE" END) AS pct_insured
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES t
    WHERE t."VARIABLE" IN ('ASSET', 'IDDEPINR')
      AND t."DATE" = '2022-12-31'
    GROUP BY t."ID_RSSD"
),
eligible AS (   -- keep banks with >$10 B in assets and a valid insured percentage
    SELECT
        p."ID_RSSD",
        p.assets_usd,
        p.pct_insured,
        (1 - p.pct_insured) * 100 AS pct_uninsured
    FROM pivoted p
    WHERE p.assets_usd  > 10000000000
      AND p.pct_insured IS NOT NULL
)
SELECT
    e."NAME" AS bank_name,
    ROUND(el.pct_uninsured, 4) AS percent_uninsured_assets
FROM eligible el
JOIN FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ENTITIES e
      ON el."ID_RSSD" = e."ID_RSSD"
WHERE e."CATEGORY" = 'Bank'
  AND e."IS_ACTIVE" = TRUE
ORDER BY percent_uninsured_assets DESC NULLS LAST, bank_name
LIMIT 10;