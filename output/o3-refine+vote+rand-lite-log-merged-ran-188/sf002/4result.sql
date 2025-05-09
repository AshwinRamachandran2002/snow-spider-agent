WITH metrics AS (
    SELECT
        e."NAME"                                              AS "BANK_NAME",
        t_assets."VALUE"                                      AS "TOTAL_ASSETS_USD",
        t_ins."VALUE"                                         AS "PCT_INSURED",
        (1 - t_ins."VALUE") * 100                             AS "PCT_UNINSURED_ASSETS"
    FROM FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_ENTITIES   e
    JOIN FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES t_assets
      ON e."ID_RSSD"::TEXT = t_assets."ID_RSSD"
    JOIN FINANCE__ECONOMICS.CYBERSYN.FINANCIAL_INSTITUTION_TIMESERIES t_ins
      ON e."ID_RSSD"::TEXT = t_ins."ID_RSSD"
    WHERE
          e."IS_ACTIVE"        = TRUE
      AND t_assets."VARIABLE"  = 'ASSET'
      AND t_assets."DATE"      = '2022-12-31'
      AND t_assets."VALUE"     >= 10000000000                -- ≥ $10 B in assets
      AND t_ins."VARIABLE"     = 'ESTINSR'                   -- % Insured (Estimated) ratio
      AND t_ins."DATE"         = '2022-12-31'
      AND t_ins."VALUE"        IS NOT NULL
)
SELECT
    "BANK_NAME",
    ROUND("PCT_UNINSURED_ASSETS", 2) AS "PCT_UNINSURED_ASSETS"
FROM metrics
ORDER BY
    "PCT_UNINSURED_ASSETS" DESC NULLS LAST
LIMIT 10;