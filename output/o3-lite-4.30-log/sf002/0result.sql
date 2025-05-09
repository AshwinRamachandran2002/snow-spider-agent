WITH insured AS (
    /* % Insured (Estimated) for 2022‑12‑31 */
    SELECT
        t."ID_RSSD",
        MAX(t."VALUE") AS "PCT_INSURED"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES t
    JOIN FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ATTRIBUTES a
      ON t."VARIABLE" = a."VARIABLE"
    WHERE a."VARIABLE_NAME" = '% Insured (Estimated)'
      AND t."DATE" = '2022-12-31'
    GROUP BY t."ID_RSSD"
),
assets AS (
    /* Total Assets for 2022‑12‑31 */
    SELECT
        t."ID_RSSD",
        MAX(t."VALUE") AS "TOTAL_ASSETS_USD"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES t
    JOIN FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ATTRIBUTES a
      ON t."VARIABLE" = a."VARIABLE"
    WHERE a."VARIABLE_NAME" = 'Total Assets'
      AND t."DATE" = '2022-12-31'
    GROUP BY t."ID_RSSD"
)
SELECT
    e."NAME"                                                     AS bank_name,
    ROUND((1 - i."PCT_INSURED") * 100, 4)                        AS percent_uninsured_assets
FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ENTITIES e
JOIN assets  a ON e."ID_RSSD" = a."ID_RSSD"
JOIN insured i ON e."ID_RSSD" = i."ID_RSSD"
WHERE e."CATEGORY" = 'Bank'
  AND e."IS_ACTIVE" = TRUE
  AND a."TOTAL_ASSETS_USD" > 10000000000        -- > $10B
ORDER BY percent_uninsured_assets DESC NULLS LAST, bank_name
LIMIT 10;