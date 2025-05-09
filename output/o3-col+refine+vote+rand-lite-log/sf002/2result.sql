SELECT
    e."NAME"                                                       AS "BANK_NAME",
    ROUND( (1 - i."VALUE") * 100 , 2 )                             AS "UNINSURED_ASSETS_PERCENT"
FROM
    "FINANCE__ECONOMICS"."CYBERSYN"."FINANCIAL_INSTITUTION_TIMESERIES"  i   -- % Insured (Estimated)
JOIN
    "FINANCE__ECONOMICS"."CYBERSYN"."FINANCIAL_INSTITUTION_TIMESERIES"  a   -- Total Assets
      ON  i."ID_RSSD" = a."ID_RSSD"
      AND a."VARIABLE" = 'ASSET'
      AND a."DATE"     = '2022-12-31'
JOIN
    "FINANCE__ECONOMICS"."CYBERSYN"."FINANCIAL_INSTITUTION_ENTITIES"    e
      ON  i."ID_RSSD" = TO_CHAR(e."ID_RSSD")        -- align text (timeseries) to numeric (entities)
      AND e."CATEGORY"   = 'Bank'
      AND e."IS_ACTIVE"  = TRUE
WHERE
      i."VARIABLE" = 'IDDEPINR'                     -- % Insured (Estimated)
  AND i."DATE"     = '2022-12-31'
  AND a."VALUE"    > 10000000000                   -- > $10 B assets
ORDER BY
    (1 - i."VALUE") DESC NULLS LAST
LIMIT 10;