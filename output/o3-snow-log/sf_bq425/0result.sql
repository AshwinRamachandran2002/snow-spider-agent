SELECT
       "trade_name",
       MAX("approval_date") AS "latest_approval_date"
FROM   EBI_CHEMBL.EBI_CHEMBL."PRODUCTS_26"
WHERE  REGEXP_REPLACE(UPPER("applicant_full_name"), '[^A-Z]', '') LIKE 'SANOFIAVENTIS%'
GROUP  BY "trade_name"
ORDER  BY "latest_approval_date" DESC NULLS LAST;