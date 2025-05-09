SELECT e."NAME" AS "Bank_Name",
       ROUND(((t_uninsured."VALUE" / t_assets."VALUE") * 100), 4) AS "Percentage_of_Uninsured_Assets"
FROM "FINANCE__ECONOMICS"."CYBERSYN"."FINANCIAL_INSTITUTION_ENTITIES" e
JOIN "FINANCE__ECONOMICS"."CYBERSYN"."FINANCIAL_INSTITUTION_TIMESERIES" t_assets
  ON e."ID_RSSD" = t_assets."ID_RSSD"
JOIN "FINANCE__ECONOMICS"."CYBERSYN"."FINANCIAL_INSTITUTION_TIMESERIES" t_uninsured
  ON e."ID_RSSD" = t_uninsured."ID_RSSD" AND t_assets."DATE" = t_uninsured."DATE"
WHERE t_assets."DATE" = '2022-12-31'
  AND t_assets."VARIABLE" = 'ASSET'
  AND t_uninsured."VARIABLE" = 'DEPUNA'
  AND t_assets."VALUE" > 10000000000
  AND e."IS_ACTIVE" = TRUE
  AND (e."END_DATE" IS NULL OR e."END_DATE" > '2022-12-31')
ORDER BY "Percentage_of_Uninsured_Assets" DESC NULLS LAST
LIMIT 10;