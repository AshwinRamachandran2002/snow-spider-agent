WITH asset_and_insurance AS (
    SELECT
        e."NAME"                                                AS bank_name,
        (1 - i."VALUE") * 100                                   AS percent_uninsured_assets
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ENTITIES       e
    JOIN FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES     a
         ON e."ID_RSSD" = a."ID_RSSD"
        AND a."VARIABLE" = 'ASSET'
        AND a."DATE"     = '2022-12-31'
    JOIN FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES     i
         ON e."ID_RSSD" = i."ID_RSSD"
        AND i."VARIABLE" = 'ESTINS'          -- % Insured (Estimated)
        AND i."DATE"     = '2022-12-31'
    WHERE e."CATEGORY" = 'Bank'
      AND e."IS_ACTIVE" = TRUE
      AND a."VALUE"    > 10000000000          -- assets > $10 B
      AND i."VALUE"    IS NOT NULL
)

SELECT
    bank_name,
    ROUND(percent_uninsured_assets, 4) AS percent_uninsured_assets
FROM asset_and_insurance
ORDER BY percent_uninsured_assets DESC NULLS LAST, bank_name
LIMIT 10;