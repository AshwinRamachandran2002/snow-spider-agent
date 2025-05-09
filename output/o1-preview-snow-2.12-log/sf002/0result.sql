SELECT e."NAME" AS "Bank_Name",
       ROUND(((td."VALUE" - di."VALUE") / ta."VALUE") * 100, 4) AS "Percentage_of_Uninsured_Assets"
FROM "FINANCE__ECONOMICS"."CYBERSYN"."FINANCIAL_INSTITUTION_ENTITIES" e
JOIN "FINANCE__ECONOMICS"."CYBERSYN"."FINANCIAL_INSTITUTION_TIMESERIES" ta
  ON e."ID_RSSD" = ta."ID_RSSD"
JOIN "FINANCE__ECONOMICS"."CYBERSYN"."FINANCIAL_INSTITUTION_TIMESERIES" td
  ON e."ID_RSSD" = td."ID_RSSD" AND ta."DATE" = td."DATE"
JOIN "FINANCE__ECONOMICS"."CYBERSYN"."FINANCIAL_INSTITUTION_TIMESERIES" di
  ON e."ID_RSSD" = di."ID_RSSD" AND ta."DATE" = di."DATE"
WHERE ta."VARIABLE" = 'ASSET'       -- Total Assets variable code
  AND td."VARIABLE" = 'DEP'         -- Total Deposits variable code
  AND di."VARIABLE" = 'DEPINSR'     -- Estimated Insured Deposits variable code
  AND ta."DATE" = '2022-12-31'
  AND ta."VALUE" > 10000000000      -- Assets over $10 billion
  AND e."IS_ACTIVE" = TRUE
ORDER BY "Percentage_of_Uninsured_Assets" DESC NULLS LAST
LIMIT 10;