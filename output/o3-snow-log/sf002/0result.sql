/* Top-10 active U.S. banks (assets > $10 B) ranked by highest share of
   uninsured assets on the 2022-12-31 call-report */

WITH bank_metrics AS (
    SELECT
        e."NAME"                                AS "BANK_NAME",
        t_asset."VALUE"                         AS "TOTAL_ASSETS_USD",
        (1 - t_ins."VALUE")                     AS "PCT_UNINSURED_ASSETS"
    FROM "FINANCE__ECONOMICS"."CYBERSYN"."FINANCIAL_INSTITUTION_ENTITIES"   e
    JOIN "FINANCE__ECONOMICS"."CYBERSYN"."FINANCIAL_INSTITUTION_TIMESERIES" t_ins
      ON e."ID_RSSD" = t_ins."ID_RSSD"
     AND t_ins."VARIABLE" = 'DEPINSR'          -- % Insured (Estimated)
     AND t_ins."UNIT"     = 'Percent'
     AND t_ins."DATE"     = '2022-12-31'
    JOIN "FINANCE__ECONOMICS"."CYBERSYN"."FINANCIAL_INSTITUTION_TIMESERIES" t_asset
      ON e."ID_RSSD" = t_asset."ID_RSSD"
     AND t_asset."VARIABLE" = 'ASSET'          -- Total assets (USD)
     AND t_asset."UNIT"    = 'USD'
     AND t_asset."DATE"    = '2022-12-31'
    WHERE e."CATEGORY"  = 'Bank'
      AND e."IS_ACTIVE" = TRUE
      AND t_asset."VALUE" >= 10000000000       -- > $10 B
)

SELECT
    "BANK_NAME",
    "PCT_UNINSURED_ASSETS"
FROM bank_metrics
ORDER BY "PCT_UNINSURED_ASSETS" DESC NULLS LAST
LIMIT 10;